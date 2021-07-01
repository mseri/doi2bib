exception CuzError of string

(** [decompress (resp, body)] returns the contents of body, decompressed
using the information from the "content-encoding" header or fails with
[CuzError msg] if there are decompression issues or an unknown algorithm
is required.
*)
val decompress : Cohttp_lwt.Response.t * Cohttp_lwt.Body.t -> string Lwt.t

(** [accept_gzde h] returns a new header including "accept-header:gzip,deflate"
if the "accept-header" key was not present or [h] was [None], and the unmodified
  headers otherwise.*)
val accept_gzde : Cohttp.Header.t option -> Cohttp.Header.t
