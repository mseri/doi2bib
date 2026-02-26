let err s = `Error (false, s)

let read_input file =
  let open In_channel in
  if file = "-" then input_all stdin
  else with_open_text file (fun ic -> input_all ic)

let bibfmt out strict single_line quiet verbose force files =
  if files = [] then
    err "No input files specified. Use --help for usage information."
  else
    try
      let contents =
        List.fold_left
          (fun acc file ->
            match acc with
            | Error _ as e -> e
            | Ok contents -> (
                try
                  let content = read_input file in
                  let file_label = if file = "-" then "stdin" else file in
                  if verbose && not quiet then
                    Printf.eprintf "  Read %s\n" file_label;
                  Ok (content :: contents)
                with e ->
                  Error
                    (Printf.sprintf "Failed to read '%s': %s" file
                       (Printexc.to_string e))))
          (Ok []) files
      in

      match contents with
      | Error msg -> err msg
      | Ok contents ->
          let combined_content = String.concat "\n\n" (List.rev contents) in
          let parse_result = Bibtex.parse_bibtex_with_errors combined_content in

          let formatted =
            if Bibtex.has_parse_errors parse_result then
              if force then (
                Printf.eprintf
                  "Warning: Found parsing errors in the BibTeX file:\n";
                List.iter
                  (fun error ->
                    Printf.eprintf "  - Line %d: %s\n" error.Bibtex.line
                      error.message)
                  (Bibtex.get_parse_errors parse_result);
                Printf.eprintf
                  "Please check your BibTeX syntax or raise an issue at \
                   https://github.com/mseri/doi2bib/issues\n\
                   Continuing with successfully parsed entries...\n\
                   %!";
                if parse_result.items = [] then (
                  Printf.eprintf
                    "Warning: No valid BibTeX entries found in the file.\n%!";
                  combined_content)
                else
                   let options =
                    { Bibtex.default_options with strict; single_line }
                  in
                  Bibtex.pretty_print_bibtex ~options parse_result.items)
              else (
                Printf.eprintf
                  "Warning: Found parsing errors in the BibTeX file:\n";
                List.iter
                  (fun error ->
                    Printf.eprintf "  - Line %d: %s\n" error.Bibtex.line
                      error.message)
                  (Bibtex.get_parse_errors parse_result);
                Printf.eprintf
                  "Please check your BibTeX syntax or raise an issue at \
                   https://github.com/mseri/doi2bib/issues\n\
                   Returning unformatted content.\n\
                   %!";
                combined_content)
            else if parse_result.items = [] then (
              Printf.eprintf
                "Warning: No valid BibTeX entries found in the file. If the \
                 bib file is well formed, please raise an issue at \
                 https://github.com/mseri/doi2bib/issues\n\
                 %!";
              combined_content)
            else
              let options =
                { Bibtex.default_options with strict; single_line }
              in
              Bibtex.pretty_print_bibtex ~options parse_result.items
          in

          (match out with
          | "stdout" -> if not quiet then print_string formatted
          | _ ->
              Out_channel.(
                with_open_text out (fun oc -> output_string oc formatted)));
          `Ok ()
    with e -> err @@ Printexc.to_string e

let () =
  let open Cmdliner in
  let out =
    let doc =
      "Saves the pretty printed bib to the specified file. If not specified, \
       writes to stdout."
    in
    Arg.(
      value & opt string "stdout" & info [ "o"; "output" ] ~docv:"OUTPUT" ~doc)
  in
  let strict =
    let doc =
      "Enable strict parsing mode that rejects BibTeX files with duplicate \
       fields."
    in
    Arg.(value & flag & info [ "s"; "strict" ] ~doc)
  in
  let single_line =
    let doc =
      "Force field values onto a single line by replacing newlines with a space."
    in
    Arg.(value & flag & info [ "l"; "single-line" ] ~doc)
  in
  let quiet =
    let doc = "Quiet mode: suppress all output except errors." in
    Arg.(value & flag & info [ "q"; "quiet" ] ~doc)
  in
  let verbose =
    let doc = "Enable verbose output showing which files are being read." in
    Arg.(value & flag & info [ "v"; "verbose" ] ~doc)
  in
  let force =
    let doc =
      "Force mode: ignore parsing errors and output only successfully parsed \
       entries."
    in
    Arg.(value & flag & info [ "f"; "force" ] ~doc)
  in
  let files =
    let doc =
      "BibTeX files to format. Use '-' to read from stdin. Multiple files can \
       be specified and will be combined."
    in
    Arg.(value & pos_all string [] & info [] ~docv:"FILES" ~doc)
  in
  let bibfmt_t =
    Term.(ret (const bibfmt $ out $ strict $ single_line $ quiet $ verbose $ force $ files))
  in
  let info =
    let doc = "A little CLI tool to pretty print bibtex files." in
    let man =
      [
        `S Manpage.s_description;
        `P
          "$(tname) reads one or more BibTeX files, parses them, and outputs \
           formatted BibTeX entries.";
        `P "Use '-' as a filename to read from stdin.";
        `S Manpage.s_examples;
        `P "Format a single file:";
        `Pre "  $(tname) bibliography.bib -o formatted.bib";
        `P "Format multiple files:";
        `Pre "  $(tname) file1.bib file2.bib -o combined.bib";
        `P "Read from stdin:";
        `Pre "  cat input.bib | $(tname) -";
        `P "Combine stdin with files:";
        `Pre "  echo '@article{...}' | $(tname) - existing.bib -o output.bib";
        `P "Format with strict mode:";
        `Pre "  $(tname) --strict bibliography.bib";
        `S Manpage.s_bugs;
        `P "Report bugs to https://github.com/mseri/doi2bib/issues";
      ]
    in
    Cmd.info "bibfmt" ~version:"%%VERSION%%" ~doc ~exits:Cmd.Exit.defaults ~man
  in
  let bibfmt = Cmd.v info bibfmt_t in
  exit @@ Cmd.eval bibfmt
