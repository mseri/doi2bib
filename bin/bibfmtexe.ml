open Doi2bib

let err s = `Error (false, s)

let bibfmt file out =
  let main =
    let open Lwt.Infix in
    let file = if file = "" then "stdin" else file in

    (* Read the input from the specified file or stdin *)
    let read_input () =
      if file = "stdin" then Lwt_io.read Lwt_io.stdin
      else Lwt_io.with_file ~mode:Lwt_io.Input file (fun ic -> Lwt_io.read ic)
    in

    read_input () >>= fun content ->
    let parsed_items = Bibtex.parse_bibtex content in

    (* Pretty print the BibTeX entries *)
    let formatted =
      if parsed_items = [] then (
        Printf.eprintf
          "Warning: we are not able to pretty print the specified bibtex file \
           please raise an issue at https://github.com/mseri/doi2bib/issues\n\
           %!";
        content)
      else Bibtex.pretty_print_bibtex parsed_items
    in

    (* Write the output *)
    match out with
    | "stdout" -> Lwt_io.print formatted
    | _ ->
        Lwt_io.with_file ~mode:Lwt_io.Output out (fun oc ->
            Lwt_io.write oc formatted)
  in
  match Lwt_main.run main with
  | () -> `Ok ()
  | exception e -> err @@ Printexc.to_string e

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
