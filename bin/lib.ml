type id =
  | DOI of string
  | ArXiv of string
  | PubMed of string

exception Parse_error of string
exception PubMed_DOI_not_found

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


let bib_of_doi doi =
  let uri = "https://doi.org/" ^ String.trim doi |> Uri.of_string in
  let headers =
    Cohttp.Header.of_list [ "Accept", "application/x-bibtex"; "charset", "utf-8" ]
  in
  let fallback =
    Uri.of_string
      ("https://citation.crosscite.org/format?doi=" ^ doi ^ "&style=bibtex&lang=en-US")
  in
  Http.get ~headers ~fallback uri


let bib_of_arxiv arxiv =
  let uri =
    "https://export.arxiv.org/api/query?id_list=" ^ String.trim arxiv |> Uri.of_string
  in
  let open Lwt.Syntax in
  let* body = Http.get uri in
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
  let* body = Http.get uri in
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
      | true -> Http.Entry_not_found
      | false -> PubMed_DOI_not_found
      | exception Ezxmlm.(Tag_not_found _) -> Http.Entry_not_found
    in
    Lwt.fail exn


let get_bib_entry = function
  | DOI doi -> bib_of_doi doi
  | ArXiv arxiv -> bib_of_arxiv arxiv
  | PubMed pubmed -> bib_of_pubmed pubmed
