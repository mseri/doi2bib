type id =
  | DOI of string
  | ArXiv of string
  | PubMed of string

exception Parse_error of string
exception Entry_not_found
exception PubMed_DOI_not_found
exception Bad_gateway

let string_of_id = function
  | DOI s -> "DOI ID '" ^ s ^ "'"
  | ArXiv s -> "arXiv ID '" ^ s ^ "'"
  | PubMed s -> "PubMed ID '" ^ s ^ "'"


let parse_id id =
  let open Astring in
  let is_prefix affix s = String.is_prefix ~affix (String.Ascii.lowercase s) in
  let sub start s = String.sub ~start s |> String.Sub.to_string |> String.trim in
  let contains c s = String.exists (fun c' -> c' = c) s in
  match id with
  | doi when is_prefix "doi:" doi -> DOI (sub 4 doi)
  | arxiv when is_prefix "arxiv:" arxiv -> ArXiv (sub 6 arxiv)
  | pubmed when is_prefix "pmc" pubmed -> PubMed pubmed
  | doi when contains '/' doi -> DOI (String.trim doi)
  | arxiv when contains '.' arxiv -> ArXiv (String.trim arxiv)
  | _ -> raise (Parse_error id)


let parse_atom id atom =
  let bibentry () =
    let open Ezxmlm in
    let entry = atom |> member "feed" |> member "entry" in
    let title = entry |> member "title" |> to_string in
    let authors =
      entry
      |> members "author"
      |> List.map (fun n -> member "name" n |> to_string)
      |> String.concat " and "
    in
    let year =
      try entry |> member "updated" |> to_string |> fun s -> String.sub s 0 4 with
      | Tag_not_found _ ->
        entry |> member "published" |> to_string |> fun s -> String.sub s 0 4
    in
    let cat =
      entry |> member_with_attr "primary_category" |> fun (a, _) -> get_attr "term" a
    in
    let bibid =
      let open Astring in
      (match String.cuts ~empty:false ~sep:" " authors with
      | _ :: s :: _ -> s
      | s :: _ -> s
      | [] -> "")
      ^ year
      ^ (String.cut ~sep:" " title |> Option.map fst |> Option.value ~default:"")
    in
    Printf.sprintf
      {|@misc{%s,
      title={%s}, 
      author={%s},
      year={%s},
      eprint={%s},
      archivePrefix={arXiv},
      primaryClass={%s}
}|}
      bibid
      title
      authors
      year
      id
      cat
  in
  try bibentry () with
  | Ezxmlm.Tag_not_found t ->
    raise
    @@ Failure ("Unexpected error parsing arXiv's metadata, tag '" ^ t ^ "' not present.")


let rec get ?headers ?fallback uri =
  let open Lwt.Syntax in
  let* resp, body = Cohttp_lwt_unix.Client.get ?headers uri in
  let code = Cohttp_lwt.(resp |> Response.status |> Cohttp.Code.code_of_status) in
  if code <> 200 then 
    Lwt.ignore_result (Cohttp_lwt.Body.drain_body body);
  match code with
  | 200 ->
    let* body = Cohttp_lwt.Body.to_string body in
    Lwt.return body
  | 302 ->
    let uri' = Cohttp_lwt.(resp |> Response.headers |> Cohttp.Header.get_location) in
    (match uri', fallback with
    | Some uri, _ -> get ?headers ?fallback uri
    | None, Some uri -> get ?headers uri
    | None, None ->
      Lwt.fail_with ("Malformed redirection trying to access '" ^ Uri.to_string uri ^ "'."))
  | d when (d = 404 || d = 504) && Option.is_some fallback ->
    (match fallback with
    | Some uri -> get ?headers uri
    | None -> assert false)
  | 400 | 404 ->
    Lwt.fail Entry_not_found
  | 502 ->
    Lwt.fail Bad_gateway
  | _ ->
    Lwt.fail_with
      ("Response error: got '"
      ^ string_of_int code
      ^ "' trying to access '"
      ^ Uri.to_string uri
      ^ "'.")


let bib_of_doi doi =
  let uri = "https://doi.org/" ^ String.trim doi |> Uri.of_string in
  let headers =
    Cohttp.Header.of_list [ "Accept", "application/x-bibtex"; "charset", "utf-8" ]
  in
  let fallback =
    Uri.of_string
      ("https://citation.crosscite.org/format?doi=" ^ doi ^ "&style=bibtex&lang=en-US")
  in
  get ~headers ~fallback uri


let bib_of_arxiv arxiv =
  let uri =
    "https://export.arxiv.org/api/query?id_list=" ^ String.trim arxiv |> Uri.of_string
  in
  let open Lwt.Syntax in
  let* body = get uri in
  let _, atom_blob = Ezxmlm.from_string body in
  try
    let doi =
      Ezxmlm.(atom_blob |> member "feed" |> member "entry" |> member "doi" |> to_string)
    in
    bib_of_doi doi
  with
  | Ezxmlm.Tag_not_found _ -> parse_atom arxiv atom_blob |> Lwt.return


let bib_of_pubmed pubmed =
  let pubmed = String.trim pubmed in
  let uri =
    "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?ids=" ^ pubmed |> Uri.of_string
  in
  let open Lwt.Syntax in
  let* body = get uri in
  let _, xml_blob = Ezxmlm.from_string body in
  try
    let doi = ref "" in
    let _ =
      Ezxmlm.filter_map
        ~tag:"record"
        ~f:(fun attrs node ->
          doi := Ezxmlm.get_attr "doi" attrs;
          node)
        xml_blob
    in
    bib_of_doi !doi
  with
  | Not_found ->
    let exn =
      match
        Ezxmlm.(
          member "pmcids" xml_blob
          |> member_with_attr "record"
          |> fun (a, _) -> mem_attr "status" "error" a)
      with
      | true -> Entry_not_found
      | false -> PubMed_DOI_not_found
      | exception Ezxmlm.(Tag_not_found _) -> Entry_not_found
    in
    Lwt.fail exn


let get_bib_entry = function
  | DOI doi -> bib_of_doi doi
  | ArXiv arxiv -> bib_of_arxiv arxiv
  | PubMed pubmed -> bib_of_pubmed pubmed


let err s = `Error (false, s)

let doi2bib id =
  match id with
  | None -> `Help (`Pager, None)
  | Some id ->
    (match Lwt_main.run (get_bib_entry @@ parse_id id) with
    | bibtex -> `Ok (Printf.printf "%s" bibtex)
    | exception PubMed_DOI_not_found ->
      err @@ Printf.sprintf "Error: unable to find a DOI entry for %s.\n" id
    | exception Entry_not_found ->
      err
      @@ Printf.sprintf
           "Error: unable to find any bibtex entry for %s.\n\
            Check the ID before trying again.\n"
           id
    | exception Failure s -> err @@ Printf.sprintf "Unexpected error. %s\n" s
    | exception Bad_gateway ->
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
