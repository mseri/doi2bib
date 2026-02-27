let err s = `Error (false, s)

let parse_keys keys_str =
  if keys_str = "" then [ "title"; "author"; "year" ]
  else String.split_on_char ',' keys_str |> List.map String.trim

let display_conflict conflict =
  Printf.printf "\nConflict in field '%s':\n" conflict.Bibtex.field_name;
  List.iteri
    (fun i (value, entry_idx) ->
      Printf.printf "  [%d] (from entry %d): %s\n" i entry_idx value)
    conflict.Bibtex.values;
  flush stdout

let prompt_user_choice conflict =
  let num_options = List.length conflict.Bibtex.values in
  let rec get_choice () =
    Printf.printf "Choose which value to keep [0-%d] (or 's' to skip): "
      (num_options - 1);
    flush stdout;
    try
      let line = input_line stdin in
      let trimmed = String.trim line in
      if trimmed = "s" || trimmed = "S" then -1
      else
        let choice = int_of_string trimmed in
        if choice >= 0 && choice < num_options then choice
        else (
          Printf.printf
            "Invalid choice. Please enter a number between 0 and %d.\n"
            (num_options - 1);
          get_choice ())
    with
    | Failure _ ->
        Printf.printf "Invalid input. Please enter a number or 's' to skip.\n";
        get_choice ()
    | End_of_file ->
        Printf.printf "\nEnd of input. Skipping this conflict.\n";
        -1
  in
  get_choice ()

(* Resolve conflicts interactively and merge entries *)
let resolve_conflicts duplicate_group =
  let base_entry = List.hd duplicate_group.Bibtex.entries in

  Printf.printf "\n=== Resolving duplicates for entry: %s ===\n"
    base_entry.Bibtex.citekey;
  Printf.printf "Found %d duplicate entries\n"
    (List.length duplicate_group.Bibtex.entries);

  (* Build a map of resolved field values *)
  let resolved_fields = Hashtbl.create 16 in

  (* First, add all fields from the base entry *)
  List.iter
    (function
      | Bibtex.Field { name; value } ->
          let name_lower = String.lowercase_ascii name in
          Hashtbl.replace resolved_fields name_lower
            (name, Bibtex.string_of_field_value value)
      | Bibtex.EntryComment _ -> ())
    base_entry.Bibtex.contents;

  (* Resolve conflicts *)
  List.iter
    (fun conflict ->
      display_conflict conflict;
      let choice = prompt_user_choice conflict in
      if choice >= 0 then
        let chosen_value, _ = List.nth conflict.Bibtex.values choice in
        let name_lower = String.lowercase_ascii conflict.Bibtex.field_name in
        Hashtbl.replace resolved_fields name_lower
          (conflict.Bibtex.field_name, chosen_value))
    duplicate_group.Bibtex.conflicts;

  (* Add any fields that don't conflict *)
  List.iter
    (fun entry ->
      List.iter
        (function
          | Bibtex.Field { name; value } ->
              let name_lower = String.lowercase_ascii name in
              if not (Hashtbl.mem resolved_fields name_lower) then
                Hashtbl.replace resolved_fields name_lower
                  (name, Bibtex.string_of_field_value value)
          | Bibtex.EntryComment _ -> ())
        entry.Bibtex.contents)
    duplicate_group.Bibtex.entries;

  (* Build the merged entry *)
  let merged_contents =
    Hashtbl.fold
      (fun _ (name, value) acc -> Bibtex.make_field name value :: acc)
      resolved_fields []
    |> List.rev
  in

  { base_entry with Bibtex.contents = merged_contents }

(* Merge entries non-interactively by keeping first occurrence of each field *)
let merge_entries_non_interactive entries =
  if entries = [] then invalid_arg "merge_entries_non_interactive: empty list"
  else
    let base_entry = List.hd entries in
    let merged_fields = Hashtbl.create 16 in

    (* Collect all fields, keeping first occurrence *)
    List.iter
      (fun entry ->
        List.iter
          (function
            | Bibtex.Field { name; value } ->
                let name_lower = String.lowercase_ascii name in
                if not (Hashtbl.mem merged_fields name_lower) then
                  Hashtbl.replace merged_fields name_lower
                    (name, Bibtex.string_of_field_value value)
            | Bibtex.EntryComment _ -> ())
          entry.Bibtex.contents)
      entries;

    (* Build merged entry *)
    let merged_contents =
      Hashtbl.fold
        (fun _ (name, value) acc -> Bibtex.make_field name value :: acc)
        merged_fields []
      |> List.rev
    in

    { base_entry with Bibtex.contents = merged_contents }

(* Main deduplication function with IO *)
let deduplicate_entries ?(keys = [ "title"; "author"; "year" ])
    ?(interactive = true) entries =
  let duplicate_groups = Bibtex.find_duplicate_groups ~keys entries in

  if duplicate_groups = [] then (
    Printf.printf "No duplicates found.\n";
    flush stdout;
    entries)
  else (
    Printf.printf "Found %d duplicate groups.\n\n"
      (List.length duplicate_groups);
    flush stdout;

    (* Create a set of entries that are duplicates *)
    let duplicate_entries = Hashtbl.create 16 in
    List.iter
      (fun group ->
        List.iter
          (fun entry ->
            Hashtbl.add duplicate_entries entry.Bibtex.citekey entry)
          group.Bibtex.entries)
      duplicate_groups;

    (* Resolve duplicates *)
    let merged_entries =
      List.map
        (fun group ->
          if interactive then resolve_conflicts group
          else merge_entries_non_interactive group.Bibtex.entries)
        duplicate_groups
    in

    (* Filter out duplicate entries and add merged ones *)
    let non_duplicates =
      List.filter
        (fun entry -> not (Hashtbl.mem duplicate_entries entry.Bibtex.citekey))
        entries
    in

    non_duplicates @ merged_entries)

let read_file filename =
  try
    let content =
      if filename = "-" then In_channel.input_all stdin
      else
        In_channel.with_open_text filename (fun ic -> In_channel.input_all ic)
    in
    Ok content
  with
  | Sys_error msg ->
      Error (Printf.sprintf "Failed to read file '%s': %s" filename msg)
  | e ->
      Error
        (Printf.sprintf "Failed to read file '%s': %s" filename
           (Printexc.to_string e))

let bibdedup keys_str interactive strict output files =
  let main () =
    if files = [] then
      err "No input files specified. Use --help for usage information."
    else
      let keys = parse_keys keys_str in

      Printf.eprintf "Using deduplication keys: [%s]\n"
        (String.concat "; " keys);
      Printf.eprintf "Reading %d file(s)...\n" (List.length files);
      flush stderr;

      (* Read all files *)
      let contents =
        List.fold_left
          (fun acc filename ->
            match acc with
            | Error _ as e -> e
            | Ok contents -> (
                match read_file filename with
                | Ok content ->
                    let file_label =
                      if filename = "-" then "stdin" else filename
                    in
                    Printf.eprintf "  Read %s\n" file_label;
                    flush stderr;
                    Ok (content :: contents)
                | Error msg -> Error msg))
          (Ok []) files
      in

      match contents with
      | Error msg -> err msg
      | Ok contents ->
          let combined_content = String.concat "\n\n" (List.rev contents) in

          (* Parse all entries *)
          Printf.eprintf "Parsing BibTeX entries...\n";
          flush stderr;
          let parse_result = Bibtex.parse_bibtex_with_errors combined_content in

          if Bibtex.has_parse_errors parse_result then (
            Printf.eprintf
              "Warning: Found parsing errors in the BibTeX files:\n";
            List.iter
              (fun error ->
                Printf.eprintf "  - Line %d: %s\n" error.Bibtex.line
                  error.message)
              (Bibtex.get_parse_errors parse_result);
            Printf.eprintf "Continuing with successfully parsed entries...\n";
            flush stderr);

          let all_items = Bibtex.get_parsed_items parse_result in
          let all_entries =
            List.filter_map
              (function Bibtex.Entry e -> Some e | Bibtex.Comment _ -> None)
              all_items
          in

          Printf.eprintf "Parsed %d entries total.\n" (List.length all_entries);
          flush stderr;

          (* Deduplicate *)
          Printf.eprintf "Deduplicating...\n\n";
          flush stderr;

          let deduplicated =
            deduplicate_entries ~keys ~interactive all_entries
          in

          Printf.eprintf "\nDeduplication complete: %d → %d entries\n"
            (List.length all_entries) (List.length deduplicated);
          flush stderr;

          (* Sort by citekey *)
          let sorted =
            List.sort
              (fun e1 e2 -> String.compare e1.Bibtex.citekey e2.Bibtex.citekey)
              deduplicated
          in

          (* Format output *)
          let output_items = List.map (fun e -> Bibtex.Entry e) sorted in
          let format_options = { Bibtex.default_options with strict } in
          let formatted =
            Bibtex.pretty_print_bibtex ~options:format_options output_items
          in

          (* Write output *)
          (match output with
          | "stdout" -> print_string formatted
          | filename ->
              Out_channel.with_open_text filename (fun oc ->
                  Out_channel.output_string oc formatted);
              Printf.eprintf "Output written to %s\n" filename;
              flush stderr);

          `Ok ()
  in
  try main () with e -> err @@ Printexc.to_string e

let () =
  let open Cmdliner in
  let keys =
    let doc =
      "Comma-separated list of field names to use for duplicate detection. \
       Special key 'citekey' matches on citation keys. Default: \
       title,author,year"
    in
    Arg.(value & opt string "" & info [ "k"; "keys" ] ~docv:"KEYS" ~doc)
  in
  let interactive =
    let doc =
      "Enable interactive mode to resolve conflicts. If not set, automatically \
       keeps the first occurrence of conflicting fields."
    in
    Arg.(value & flag & info [ "i"; "interactive" ] ~doc)
  in
  let strict =
    let doc =
      "Enable strict mode that checks for and reports duplicate fields in \
       entries."
    in
    Arg.(value & flag & info [ "s"; "strict" ] ~doc)
  in
  let output =
    let doc =
      "Output file for deduplicated BibTeX. If not specified, writes to stdout."
    in
    Arg.(
      value & opt string "stdout" & info [ "o"; "output" ] ~docv:"OUTPUT" ~doc)
  in
  let files =
    let doc =
      "BibTeX files to deduplicate. Use '-' to read from stdin. Multiple file \
       names can be specified."
    in
    Arg.(value & pos_all string [] & info [] ~docv:"FILES" ~doc)
  in
  let bibdedup_t =
    Term.(ret (const bibdedup $ keys $ interactive $ strict $ output $ files))
  in
  let info =
    let doc = "Deduplicate BibTeX entries across multiple files." in
    let man =
      [
        `S Manpage.s_description;
        `P
          "$(tname) reads one or more BibTeX files, combines all entries, and \
           removes duplicates based on specified key fields.";
        `P
          "By default, entries are considered duplicates if they have the same \
           title, author, and year (after whitespace normalization and \
           case-insensitive comparison).";
        `S Manpage.s_examples;
        `P "Deduplicate a single file:";
        `Pre "  $(tname) bibliography.bib -o clean.bib";
        `P "Deduplicate multiple files using DOI:";
        `Pre "  $(tname) --keys doi file1.bib file2.bib -o merged.bib";
        `P "Read from stdin:";
        `Pre "  cat input.bib | $(tname) -";
        `P "Combine stdin with files:";
        `Pre "  cat extra.bib | $(tname) - existing.bib -o output.bib";
        `P "Deduplicate using citekey with interactive conflict resolution:";
        `Pre "  $(tname) --keys citekey --interactive *.bib -o output.bib";
        `P "Deduplicate with strict mode (reports duplicate fields):";
        `Pre "  $(tname) --strict --keys doi file1.bib file2.bib -o clean.bib";
        `P "Deduplicate and output to stdout:";
        `Pre "  $(tname) --keys title,year file1.bib file2.bib";
        `S Manpage.s_bugs;
        `P "Report bugs to https://github.com/mseri/doi2bib/issues";
      ]
    in
    Cmd.info "bibdedup" ~version:"%%VERSION%%" ~doc ~exits:Cmd.Exit.defaults
      ~man
  in
  let bibdedup = Cmd.v info bibdedup_t in
  exit @@ Cmd.eval bibdedup
