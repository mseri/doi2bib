type id = DOI of string | ArXiv of string | PubMed of string

exception Parse_error of string

let string_of_id = function
  | DOI s -> "DOI ID '" ^ s ^ "'"
  | ArXiv s -> "arXiv ID '" ^ s ^ "'"
  | PubMed s -> "PubMed ID '" ^ s ^ "'"

let parse_id id =
  let is_prefix affix s =
    let n = String.length affix in
    String.length s >= n && String.sub (String.lowercase_ascii s) 0 n = affix
  in
  let sub start s = String.trim (String.sub s start (String.length s - start)) in
  match id with
  | doi when is_prefix "doi:" doi -> DOI (sub 4 doi)
  | arxiv when is_prefix "arxiv:" arxiv -> ArXiv (sub 6 arxiv)
  | pubmed when is_prefix "pmc" pubmed -> PubMed pubmed
  | doi when String.contains doi '/' -> DOI (String.trim doi)
  | arxiv when String.contains arxiv '.' -> ArXiv (String.trim arxiv)
  | _ -> raise (Parse_error id)

let parse_atom id atom =
  let bibentry () =
    let open Ezxmlm in
    let entry = atom |> member "feed" |> member "entry" in
    let title = entry |> member "title" |> to_string in
    let authors =
      entry |> members "author"
      |> List.map (fun n -> member "name" n |> to_string)
      |> String.concat " and "
    in
    let year =
      try entry |> member "updated" |> to_string |> fun s -> String.sub s 0 4
      with Tag_not_found _ ->
        entry |> member "published" |> to_string |> fun s -> String.sub s 0 4
    in
    let cat =
      entry |> member_with_attr "primary_category" |> fun (a, _) ->
      get_attr "term" a
    in
    let bibid =
      (match String.split_on_char ' ' authors |> List.filter (fun s -> s <> "") with
      | _ :: s :: _ -> s
      | s :: _ -> s
      | [] -> "")
      ^ year
      ^ (match String.index_opt title ' ' with
         | Some i -> String.sub title 0 i
         | None -> "")
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
      bibid title authors year id cat
  in
  try bibentry ()
  with Ezxmlm.Tag_not_found t ->
    raise
    @@ Failure
         ("Unexpected error parsing arXiv's metadata, tag '" ^ t
        ^ "' not present.")
