type id =
  | DOI of string
  | ArXiv of string

let parse_args () =
  Clap.description "A little CLI tool to get the bibtex entry for a given DOI or arXivID.";
  let id =
    Clap.mandatory_string
      ~last:true
      ~description:
        "A DOI or an arXiv ID. The tool tries to automatically infer what kind of ID you \
         are using. You can force the cli to lookup a DOI by using the form 'doi:ID' or \
         an arXiv ID by using the form 'arXiv:ID'."
      ~placeholder:"ID"
      ()
  in
  Clap.close ();
  id


let parse_id id =
  let open Astring in
  let is_prefix affix s = String.is_prefix ~affix (String.Ascii.lowercase s) in
  let sub start s = String.sub ~start s |> String.Sub.to_string |> String.trim in
  let contains c s = String.exists (fun c' -> c' = c) s in
  match id with
  | doi when is_prefix "doi:" doi -> DOI (sub 4 doi)
  | arxiv when is_prefix "arxiv:" arxiv -> ArXiv (sub 6 arxiv)
  | doi when contains '/' doi -> DOI (String.trim doi)
  | arxiv when contains '.' arxiv -> ArXiv (String.trim arxiv)
  | _ ->
    failwith
      ("Unable to parse ID: '"
      ^ id
      ^ "'. You can force me to consider it by prepending 'doi:' or 'arxiv:' as \
         appropriate.")


let parse_atom id atom =
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


let rec get ?headers ?fallback uri =
  let open Lwt.Syntax in
  let* resp, body = Cohttp_lwt_unix.Client.get ?headers uri in
  let code = Cohttp_lwt.(resp |> Response.status |> Cohttp.Code.code_of_status) in
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
  | _ ->
    Lwt.fail_with
      ("Unexpected response: got '"
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


let get_bib_entry = function
  | DOI doi -> bib_of_doi doi
  | ArXiv arxiv -> bib_of_arxiv arxiv


let () =
  let id = parse_args () |> parse_id in
  let open Lwt.Syntax in
  Lwt_main.run
    (let* bibtex = get_bib_entry id in
     Lwt_io.printf "%s" bibtex)
