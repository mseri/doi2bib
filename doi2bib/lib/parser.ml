type id = DOI of string | ArXiv of string | PubMed of string

exception Parse_error of string

let string_of_id = function
  | DOI s -> "DOI ID '" ^ s ^ "'"
  | ArXiv s -> "arXiv ID '" ^ s ^ "'"
  | PubMed s -> "PubMed ID '" ^ s ^ "'"

let parse_id id =
  let open Astring in
  let is_prefix affix s = String.is_prefix ~affix (String.Ascii.lowercase s) in
  let sub start s =
    String.sub ~start s |> String.Sub.to_string |> String.trim
  in
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
      bibid title authors year id cat
  in
  try bibentry ()
  with Ezxmlm.Tag_not_found t ->
    raise
    @@ Failure
         ("Unexpected error parsing arXiv's metadata, tag '" ^ t
        ^ "' not present.")
