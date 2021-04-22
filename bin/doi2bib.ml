open Doi2bib

let err s = `Error (false, s)

let doi2bib id =
  match id with
  | None -> `Help (`Pager, None)
  | Some id ->
    (match Lwt_main.run (get_bib_entry @@ parse_id id) with
    | bibtex -> `Ok (Printf.printf "%s" bibtex)
    | exception PubMed_DOI_not_found ->
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
            This error tends to happen when the remote servers are busy."
    | exception Parse_error id ->
      err
      @@ Printf.sprintf
           "Error: unable to parse ID: '%s'.\n\
            You can force me to consider it by prepending 'doi:', 'arxiv:' or 'PMC' as \
            appropriate."
           id)


let () =
  let open Cmdliner in
  let id =
    let doc =
      "A DOI, an arXiv ID or a PubMed ID. The tool tries to automatically infer what \
       kind of ID you are using. You can force the cli to lookup a DOI by using the form \
       'doi:ID' or an arXiv ID by using the form 'arXiv:ID'.\n\
       PubMed IDs always start with 'PMC'."
    in
    Arg.(value & pos 0 (some string) None & info ~docv:"ID" ~doc [])
  in
  let doi2bib_t = Term.(ret (const doi2bib $ id)) in
  let info =
    let doc =
      "A little CLI tool to get the bibtex entry for a given DOI, arXiv or PubMed ID."
    in
    let man =
      [ `S Manpage.s_bugs; `P "Report bugs to https://github.com/mseri/doi2bib/issues" ]
    in
    Term.info "doi2bib" ~version:"%%VERSION%%" ~doc ~exits:Term.default_exits ~man
  in
  Term.exit @@ Term.eval (doi2bib_t, info)
