open Js_of_ocaml
open Js_of_ocaml_lwt
module Html = Dom_html

let proxy = "https://thingproxy.freeboard.io/fetch/"

module Ezgz = struct
  exception GzipError of string

  let extract _ s = s
  let gzip_h h = h
end

let onload _ =
  let open Doi2bib in
  let open Http.Make (Cohttp_lwt_jsoo.Client) (Ezgz) in
  (* let d = Html.document in *)
  let out : Html.divElement Js.t =
    match Html.getElementById_coerce "doi2bib-out" Html.CoerceTo.div with
    | Some el -> el
    | None -> assert false
  in
  let id : Html.inputElement Js.t =
    match Html.getElementById_coerce "doi2bib-txt" Html.CoerceTo.input with
    | Some el -> el
    | None -> assert false
  in
  let btn : Html.buttonElement Js.t =
    match Html.getElementById_coerce "doi2bib-btn" Html.CoerceTo.button with
    | Some el -> el
    | None -> assert false
  in
  let open Lwt.Syntax in
  Lwt_js_events.(
    async (fun () ->
        clicks btn (fun _ _ ->
            let id' = id##.value |> Js.to_string |> Parser.parse_id in
            print_endline (id##.value |> Js.to_string);
            let* bibtex =
              Lwt.catch
                (fun () -> get_bib_entry ~proxy id')
                (fun err -> Lwt.return @@ Printexc.to_string err)
            in
            out##.innerHTML := Js.string bibtex;
            Lwt.return_unit)));
  Js._true


let _ = Html.window##.onload := Html.handler onload
