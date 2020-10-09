let unimplemented () = raise @@ Invalid_argument "unimplemented"
let parse_id _id = unimplemented ()

let bib_of_doi doi =
  let open Cohttp in
  let headers = Header.of_list [ "Accept", "application/x-bibtex"; "charset", "utf-8" ] in
  let uri = "https://doi.org/" ^ String.trim doi |> Uri.of_string in
  let%lwt resp, body = Cohttp_lwt_unix.Client.get ~headers uri in
  let code = Cohttp_lwt.(resp |> Response.status |> Code.code_of_status) in
  if code = 200
  then body |> Cohttp_lwt.Body.to_string
  else Lwt.fail_with ("Response status error: expected 200, got " ^ string_of_int code)


let bib_of_arxiv _id = unimplemented ()

let () =
  Clap.description "A little CLI tool to get the bibtex entry for a given DOI or arXivID.";
  let inference_typ = Clap.enum "type" [ "arxiv", `arxiv; "doi", `doi ] in
  let inference = Clap.optional inference_typ () in
  let id = Clap.mandatory_string ~last:true ~placeholder:"ID" () in
  let bibtex =
    match inference with
    | None -> Lwt.fail Not_found
    | Some `doi -> bib_of_doi id
    | Some `arxiv -> Lwt.fail Not_found
  in
  Lwt_main.run
    (let%lwt bibtex = bibtex in
     Lwt_io.printf "%s" bibtex)
