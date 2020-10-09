type id =
  | DOI of string
  | ArXiv of string

let parse_args () =
  Clap.description "A little CLI tool to get the bibtex entry for a given DOI or arXivID.";
  let id =
    Clap.mandatory_string
      ~last:true
      ~description:
        "A DOI or an arXiv ID. The DOI nust be in the form 'prefix/suffix' or \
         'doi:prefix/suffix' while the arXiv ID must be in the form 'value.value' or \
         'arXiv:value.value'"
      ~placeholder:"ID"
      ()
  in
  Clap.close ();
  id


let parse_id id =
  let open Astring in
  match id with
  | doi when String.is_prefix ~affix:"doi:" (String.Ascii.lowercase doi) ->
    String.sub ~start:4 doi |> String.Sub.to_string |> fun s -> DOI (String.trim s)
  | doi when String.exists (fun c -> c = '/') doi -> DOI (String.trim doi)
  | arxiv when String.is_prefix ~affix:"arxiv:" (String.Ascii.lowercase arxiv) ->
    String.sub ~start:6 arxiv |> String.Sub.to_string |> fun s -> ArXiv (String.trim s)
  | arxiv when String.exists (fun c -> c = '.') arxiv -> ArXiv (String.trim arxiv)
  | id -> failwith ("Malformed ID: " ^ id)


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
    | Ezxmlm.Tag_not_found _ ->
      entry |> member "published" |> to_string |> fun s -> String.sub s 0 4
  in
  let cat =
    entry |> member_with_attr "primary_category" |> fun (a, _) -> get_attr "term" a
  in
  let bibid =
    (match Astring.String.cuts ~empty:false ~sep:" " authors with
    | _ :: s :: _ -> s
    | s :: _ -> s
    | [] -> "")
    ^ year
    ^ (Astring.String.cut ~sep:" " title |> Option.value ~default:("", "") |> fst)
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


let bib_of_doi doi =
  let uri = "https://doi.org/" ^ String.trim doi |> Uri.of_string in
  let open Cohttp in
  let headers = Header.of_list [ "Accept", "application/x-bibtex"; "charset", "utf-8" ] in
  let%lwt resp, body = Cohttp_lwt_unix.Client.get ~headers uri in
  let code = Cohttp_lwt.(resp |> Response.status |> Code.code_of_status) in
  match code with
  | 200 -> body |> Cohttp_lwt.Body.to_string
  | 302 ->
    let uri = Cohttp_lwt.(resp |> Response.headers |> Header.get_location) in
    (match uri with
    | Some uri ->
      let%lwt resp, body = Cohttp_lwt_unix.Client.get ~headers uri in
      let code = Cohttp_lwt.(resp |> Response.status |> Code.code_of_status) in
      if code = 200
      then body |> Cohttp_lwt.Body.to_string
      else
        Lwt.fail_with
          ("Response status error (2): expected 200, got " ^ string_of_int code)
    | None -> Lwt.fail_with "Response status error: cannot obtain bibtex entry")
  | _ -> Lwt.fail_with ("Response status error: expected 200, got " ^ string_of_int code)


let bib_of_arxiv arxiv =
  let uri =
    "https://export.arxiv.org/api/query?id_list=" ^ String.trim arxiv |> Uri.of_string
  in
  let open Cohttp in
  let%lwt resp, body = Cohttp_lwt_unix.Client.get uri in
  let code = Cohttp_lwt.(resp |> Response.status |> Code.code_of_status) in
  match code with
  | 200 ->
    let%lwt body = body |> Cohttp_lwt.Body.to_string in
    let _, atom_blob = Ezxmlm.from_string body in
    let open Ezxmlm in
    (try
       let doi =
         atom_blob |> member "feed" |> member "entry" |> member "doi" |> to_string
       in
       bib_of_doi doi
     with
    | Ezxmlm.Tag_not_found _ -> parse_atom arxiv atom_blob |> Lwt.return)
  | _ -> Lwt.fail_with ("Response status error: expected 200, got " ^ string_of_int code)


let () =
  let id = parse_args () |> parse_id in
  let bibtex =
    match id with
    | DOI doi -> bib_of_doi doi
    | ArXiv arxiv ->
      print_endline arxiv;
      bib_of_arxiv arxiv
  in
  Lwt_main.run
    (let%lwt bibtex = bibtex in
     Lwt_io.printf "%s" bibtex)
