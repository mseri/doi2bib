open Doi2bib

let err s = `Error (false, s)

let process_id outfile id =
  let open Lwt.Syntax in
  let* bibtex = Http.get_bib_entry @@ Parser.parse_id id in

  (* Parse and format the BibTeX *)
  let parsed_items = Bibtex.parse_bibtex bibtex in
  let formatted =
    if List.length parsed_items = 0 then (
      Printf.eprintf
        "\n\
         Error: unable to parse the BibTeX entry for %s.\n\
         Please report this issue at github.com/mseri/doi2bib/issues"
        id;
      bibtex)
    else
      (* Pretty print the BibTeX entries *)
      Bibtex.pretty_print_bibtex parsed_items
  in

  (* Write the output *)
  match outfile with
  | "stdout" -> Lwt_io.print formatted
  | outfile ->
      let flags = [ Unix.O_WRONLY; O_APPEND; O_CREAT ] in
      Lwt_io.with_file ~mode:Output ~flags outfile (fun oc ->
          Lwt_io.write_line oc formatted)

let process_file outfile infile =
  let open Lwt.Syntax in
  let lines ic =
    Lwt_seq.unfold_lwt
      (fun ic ->
        let* line = Lwt_io.read_line_opt ic in
        Lwt.return @@ Option.map (fun x -> (x, ic)) line)
      ic
  in
  let bibtex_buffer = Buffer.create 1024 in

  let process id =
    Lwt.catch
      (fun () ->
        let* bibtex = Http.get_bib_entry @@ Parser.parse_id id in
        Buffer.add_string bibtex_buffer bibtex;
        Buffer.add_string bibtex_buffer "\n";
        Lwt.return_unit)
      (fun e -> Lwt_io.eprintf "Error for %s: %s\n" id (Printexc.to_string e))
  in

  let write_out () =
    let bibtex_out = Buffer.contents bibtex_buffer in
    let parsed_items = Bibtex.parse_bibtex bibtex_out in
    let formatted = Bibtex.pretty_print_bibtex parsed_items in

    match outfile with
    | "stdout" -> Lwt_io.print formatted
    | outfile ->
        let flags = [ Unix.O_WRONLY; O_APPEND; O_CREAT ] in
        Lwt_io.with_file ~mode:Output ~flags outfile (fun oc ->
            Lwt_io.write oc formatted)
  in

  Lwt_io.with_file ~mode:Input infile (fun ic ->
      let* () = Lwt_seq.iter_s process (lines ic) in
      write_out ())

let doi2bib id file outfile =
  match (id, file) with
  | None, "" -> `Help (`Pager, None)
  | None, infile -> (
      match Lwt_main.run (process_file outfile infile) with
      | () -> `Ok ()
      | exception e -> err @@ Printexc.to_string e)
  | Some id, "" -> (
      match Lwt_main.run (process_id outfile id) with
      | () -> `Ok ()
      | exception Http.PubMed_DOI_not_found ->
          err @@ Printf.sprintf "Error: unable to find a DOI entry for %s.\n" id
      | exception Http.Entry_not_found ->
          err
          @@ Printf.sprintf
               "Error: unable to find any bibtex entry for %s.\n\
                Check the ID before trying again.\n"
               id
      | exception Failure s -> err @@ Printf.sprintf "Unexpected error. %s\n" s
      | exception Http.Bad_gateway ->
          err
          @@ Printf.sprintf
               "Remote server error: wait some time and try again.\n\
                This error tends to happen when the remote servers are busy.\n"
      | exception Parser.Parse_error id ->
          err
          @@ Printf.sprintf
               "Error: unable to parse ID: '%s'.\n\
                You can force me to consider it by prepending 'doi:', 'arxiv:' \
                or 'PMC' as appropriate.\n"
               id)
  | Some _, _ -> `Help (`Pager, None)

let () =
  let open Cmdliner in
  let file =
    let doc =
      "With this flag, the tool reads the file and process its lines \
       sequentially, treating them as DOIs, arXiv IDs or PubMedIDs. Errors \
       will be printed on standard error but will not terminate the operation."
    in
    Arg.(value & opt string "" & info [ "f"; "file" ] ~docv:"FILE" ~doc)
  in
  let out =
    let doc =
      "Append the bibtex output to the specified file. It will create the file \
       if it does not exist."
    in
    Arg.(
      value & opt string "stdout" & info [ "o"; "output" ] ~docv:"OUTPUT" ~doc)
  in
  let id =
    let doc =
      "A DOI, an arXiv ID or a PubMed ID. The tool tries to automatically \
       infer what kind of ID you are using. You can force the cli to lookup a \
       DOI by using the form 'doi:ID' or an arXiv ID by using the form \
       'arXiv:ID'.\n\
       PubMed IDs always start with 'PMC'."
    in
    Arg.(value & pos 0 (some string) None & info ~docv:"ID" ~doc [])
  in
  let doi2bib_t = Term.(ret (const doi2bib $ id $ file $ out)) in
  let info =
    let doc =
      "A little CLI tool to get the bibtex entry for a given DOI, arXiv or \
       PubMed ID."
    in
    let man =
      [
        `S Manpage.s_bugs;
        `P "Report bugs to https://github.com/mseri/doi2bib/issues";
      ]
    in
    Cmd.info "doi2bib" ~version:"%%VERSION%%" ~doc ~exits:Cmd.Exit.defaults ~man
  in
  let doi2bib = Cmd.v info doi2bib_t in
  exit @@ Cmd.eval doi2bib
