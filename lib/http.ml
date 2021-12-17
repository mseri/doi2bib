open Parser

exception Entry_not_found
exception Bad_gateway
exception PubMed_DOI_not_found

let rec get ?proxy ?headers ?fallback uri =
  let headers = Clz_cohttp.update_header headers in
  let uri = Option.value ~default:"" proxy ^ uri |> Uri.of_string in
  let open Lwt.Syntax in
  let* resp, body = Cohttp_lwt_unix.Client.get ~headers uri in
  let status = Cohttp_lwt.Response.status resp in
  let* () =
    if status <> `OK then Cohttp_lwt.Body.drain_body body else Lwt.return_unit
  in
  match status with
  | `OK -> Clz_cohttp.decompress (resp, body)
  | `Found -> (
      let uri' =
        Cohttp_lwt.(resp |> Response.headers |> Cohttp.Header.get_location)
      in
      match (uri', fallback) with
      | Some uri, _ -> get ?proxy ~headers ?fallback (Uri.to_string uri)
      | None, Some uri -> get ?proxy ~headers uri
      | None, None ->
          Lwt.fail_with
            ("Malformed redirection trying to access '" ^ Uri.to_string uri
           ^ "'."))
  | d when (d = `Not_found || d = `Gateway_timeout) && Option.is_some fallback
    -> (
      match fallback with
      | Some uri -> get ?proxy ~headers uri
      | None -> assert false)
  | `Bad_request | `Not_found -> Lwt.fail Entry_not_found
  | `Bad_gateway -> Lwt.fail Bad_gateway
  | _ ->
      Lwt.fail_with
        ("Response error: '"
        ^ Cohttp.Code.string_of_status status
        ^ "' trying to access '" ^ Uri.to_string uri ^ "'.")

let bib_of_doi ?proxy doi =
  let uri =
    "https://api.crossref.org/works/" ^ String.trim doi
    ^ "/transform/application/x-bibtex"
  in
  let headers =
    Cohttp.Header.of_list
      [ ("Accept", "text/bibliography; style=bibtex"); ("charset", "utf-8") ]
  in
  let open Lwt.Syntax in
  let* body = get ?proxy ~headers uri in
  Lwt.return body

let bib_of_arxiv ?proxy arxiv =
  let uri = "https://export.arxiv.org/api/query?id_list=" ^ String.trim arxiv in
  let open Lwt.Syntax in
  let* body = get ?proxy uri in
  let _, atom_blob = Ezxmlm.from_string body in
  try
    let doi =
      Ezxmlm.(
        atom_blob |> member "feed" |> member "entry" |> member "doi"
        |> to_string)
    in
    bib_of_doi ?proxy doi
  with Ezxmlm.Tag_not_found _ ->
    Lwt.catch
      (fun () -> get ("https://arxiv.org/bibtex/" ^ String.trim arxiv))
      (fun _e -> parse_atom arxiv atom_blob |> Lwt.return)

let bib_of_pubmed ?proxy pubmed =
  let pubmed = String.trim pubmed in
  let uri =
    "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?ids=" ^ pubmed
  in
  let open Lwt.Syntax in
  let* body = get ?proxy uri in
  let _, xml_blob = Ezxmlm.from_string body in
  try
    let doi = ref "" in
    let _ =
      Ezxmlm.filter_map ~tag:"record"
        ~f:(fun attrs node ->
          doi := Ezxmlm.get_attr "doi" attrs;
          node)
        xml_blob
    in
    bib_of_doi ?proxy !doi
  with Not_found ->
    let exn =
      match
        Ezxmlm.(
          member "pmcids" xml_blob |> member_with_attr "record" |> fun (a, _) ->
          mem_attr "status" "error" a)
      with
      | true -> Entry_not_found
      | false -> PubMed_DOI_not_found
      | exception Ezxmlm.(Tag_not_found _) -> Entry_not_found
    in
    Lwt.fail exn

let get_bib_entry ?proxy = function
  | DOI doi -> bib_of_doi ?proxy doi
  | ArXiv arxiv -> bib_of_arxiv ?proxy arxiv
  | PubMed pubmed -> bib_of_pubmed ?proxy pubmed
