open Cuz_decompress

let inflate_string ~algorithm str =
  match algorithm with
  | `Deflate -> inflate_string_de str
  | `Gzip -> inflate_string_gz str


let deflate_string ~algorithm ~cfg ?level str =
  match algorithm with
  | `Deflate -> deflate_string_de str
  | `Gzip -> deflate_string_gz ~cfg ?level str
