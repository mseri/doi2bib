let err s = `Error (false, s)

let bibfmt file out =
  let main () =
    let file = if file = "" then "stdin" else file in

    let read_input () =
      let open In_channel in
      if file = "stdin" then input_all stdin
      else with_open_text file (fun ic -> input_all ic)
    in

    let content = read_input () in
    let parse_result = Bibtex.parse_bibtex_with_errors content in

    let formatted =
      if Bibtex.has_parse_errors parse_result then (
        Printf.eprintf "Warning: Found parsing errors in the BibTeX file:\n";
        List.iter
          (fun error ->
            Printf.eprintf "  - Line %d: %s\n" error.Bibtex.line error.message)
          (Bibtex.get_parse_errors parse_result);
        Printf.eprintf
          "Please check your BibTeX syntax or raise an issue at \
           https://github.com/mseri/doi2bib/issues\n\
           Returning unformatted content.\n\
           %!";
        content)
      else if parse_result.items = [] then (
        Printf.eprintf
          "Warning: No valid BibTeX entries found in the file. Please raise an \
           issue at https://github.com/mseri/doi2bib/issues\n\
           %!";
        content)
      else Bibtex.pretty_print_bibtex parse_result.items
    in

    match out with
    | "stdout" -> print_string formatted
    | _ ->
        Out_channel.(with_open_text out (fun oc -> output_string oc formatted))
  in
  try
    main ();
    `Ok ()
  with e -> err @@ Printexc.to_string e

let () =
  let open Cmdliner in
  let file =
    let doc =
      "Reads the bib content from the specified file instead of the standard \
       input."
    in
    Arg.(value & opt string "" & info [ "f"; "file" ] ~docv:"FILE" ~doc)
  in
  let out =
    let doc = "Saves the pretty printed bib to the specified file." in
    Arg.(
      value & opt string "stdout" & info [ "o"; "output" ] ~docv:"OUTPUT" ~doc)
  in
  let bibfmt_t = Term.(ret (const bibfmt $ file $ out)) in
  let info =
    let doc = "A little CLI tool to pretty print bibtex files." in
    let man =
      [
        `S Manpage.s_bugs;
        `P "Report bugs to https://github.com/mseri/doi2bib/issues";
      ]
    in
    Cmd.info "bibfmt" ~version:"%%VERSION%%" ~doc ~exits:Cmd.Exit.defaults ~man
  in
  let bibfmt = Cmd.v info bibfmt_t in
  exit @@ Cmd.eval bibfmt
