let err s = `Error (false, s)

let parse_keys keys_str =
  if keys_str = "" then [ "title"; "author"; "year" ]
  else String.split_on_char ',' keys_str |> List.map String.trim

let read_file filename =
  try
    let content =
      In_channel.with_open_text filename (fun ic -> In_channel.input_all ic)
    in
    Ok content
  with e ->
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
                    Printf.eprintf "  ✓ Read %s\n" filename;
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
            Bibtex.deduplicate_entries ~keys ~interactive all_entries
          in

          Printf.eprintf "\nDeduplication complete: %d → %d entries\n"
            (List.length all_entries) (List.length deduplicated);
          flush stderr;

          (* Format output *)
          let output_items = List.map (fun e -> Bibtex.Entry e) deduplicated in
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
    let doc = "BibTeX files to deduplicate." in
    Arg.(value & pos_all file [] & info [] ~docv:"FILES" ~doc)
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
