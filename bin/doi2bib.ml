let unimplemented () = raise @@ Invalid_argument "unimplemented"

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


let parse_id _id = unimplemented ()

let bib_of_doi doi =
  let open Cohttp in
  let headers = Header.of_list [ "Accept", "application/x-bibtex"; "charset", "utf-8" ] in
  let uri = "https://doi.org/" ^ String.trim doi |> Uri.of_string in
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
          ("Reesponse status error (2): expected 200, got " ^ string_of_int code)
    | None -> Lwt.fail_with "Response status error: cannot obtain bibtex entry")
  | _ -> Lwt.fail_with ("Response status error: expected 200, got " ^ string_of_int code)


let bib_of_arxiv _id = unimplemented ()

type id =
  | DOI of string
  | ArXiv of string

let () =
  let id =
    let open Astring in
    parse_args ()
    |> function
    | doi when String.is_prefix ~affix:"doi:" (String.Ascii.lowercase doi) ->
      String.sub ~start:0 ~stop:3 doi
      |> String.Sub.to_string
      |> fun s -> DOI (String.trim s)
    | doi when String.exists (fun c -> c = '/') doi -> DOI (String.trim doi)
    | arxiv when String.is_prefix ~affix:"arxiv:" (String.Ascii.lowercase arxiv) ->
      String.sub ~start:0 ~stop:5 arxiv
      |> String.Sub.to_string
      |> fun s -> ArXiv (String.trim s)
    | arxiv when String.exists (fun c -> c = '.') arxiv -> ArXiv (String.trim arxiv)
    | id -> failwith ("Malformed ID: " ^ id)
  in
  let bibtex =
    match id with
    | DOI doi -> bib_of_doi doi
    | ArXiv _arxiv -> Lwt.fail Not_found
  in
  Lwt_main.run
    (let%lwt bibtex = bibtex in
     Lwt_io.printf "%s" bibtex)
