let decode_html_entities s =
  let replacements =
    [
      ("&amp;", "&");
      ("&quot;", "\"");
      ("&apos;", "'");
      ("&copy;", "(c)");
      ("&reg;", "(r)");
      ("&trade;", "(tm)");
      ("&nbsp;", " ");
    ]
  in
  List.fold_left
    (fun acc (pattern, replacement) ->
      let re = Re.compile (Re.str pattern) in
      Re.replace_string ~all:true re ~by:replacement acc)
    s replacements

let escape_ampersand s =
  (* We want to match '&' that is not preceded by '\', but the re library
     does not support lookbehind, so we can match either the start of the string or a non-backslash character before '&', keep it and replace
     the remaining '&' by '\&' *)
  let re = Re.compile (Re.seq [ Re.group (Re.alt [ Re.bos; Re.compl [ Re.char '\\' ] ]); Re.char '&' ]) in
  Re.replace re
    ~f:(fun subs ->
      let prefix = Re.Group.get subs 1 in
      prefix ^ "\\&")
    s

(* The doi API can return html entities more or less everywhere in the fields
   content, so we need to replace them. So far we replace some common ones
   and make sure to escape the '&'. It can still fail if the entry includes #
   or % (this is already treated in URLs), but I'd wait for it to happen
   before taking any further action. *)
let clean_string s = s |> decode_html_entities |> escape_ampersand

let clean_field_value =
  let open Bibtex in
  function
  | QuotedStringValue s -> QuotedStringValue (clean_string s)
  | BracedStringValue s -> BracedStringValue (clean_string s)
  | UnquotedStringValue s -> UnquotedStringValue (clean_string s)
  | NumberValue n -> NumberValue n

let clean_item =
  let open Bibtex in
  function
  | Entry e ->
      let clean_content = function
        | Field f -> Field { f with value = clean_field_value f.value }
        | EntryComment c -> EntryComment c
      in
      Entry { e with contents = List.map clean_content e.contents }
  | Comment c -> Comment c
