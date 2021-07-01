(**
  The implementation is mostly out of deflate documentation.
  It should be possible, is somebody wants to give it a try, to abstract
  the current interfaces over Cohttp and Lwt and have an implementation
  that can work with streamed response bodies and that does direct output
  to file.
  The current basic implementation is more than enough for my limited needs.

  [deflate_string] requires an external configuration only because I have been
  playing around with this also in [js_of_ocaml]. If you don't mind linking
  against [unix] you can use {!Cuz_unix.cfg}, part of the [cuz.unix] sub-library.

  The [cuz.cohttp] library contains the module {!Cuz_cohttp}, which provides
  some helpers to add the necessary accept headers and to decompress the response
  bodies.
*)

(** [inflate_string ~algorithm body] returns [body] compressed using [algorithm]
or the respective error message. *)
val inflate_string
  :  algorithm:[< `Deflate | `Gzip ]
  -> string
  -> (string, [> `Msg of string ]) result

(** [deflate_string ~algorithm ~cfg ?level body] extract the content of [body]
using [algorithm] or the respective error message. If the algorithm is gzip, it
will use [cfg] and [level] for the decompression. *)
val deflate_string
  :  algorithm:[< `Deflate | `Gzip ]
  -> cfg:unit Gz.Higher.configuration
  -> ?level:int
  -> string
  -> string
