(* Mostly from deflate.gz documentation :) *)

let uncompress_string str =
  let i = De.bigstring_create De.io_buffer_size in
  let o = De.bigstring_create De.io_buffer_size in
  let r = Buffer.create 0x1000 in
  let p = ref 0 in
  let refill buf =
    let len = min (String.length str - !p) De.io_buffer_size in
    Bigstringaf.blit_from_string str ~src_off:!p buf ~dst_off:0 ~len;
    p := !p + len;
    len
  in
  let flush buf len =
    let str = Bigstringaf.substring buf ~off:0 ~len in
    Buffer.add_string r str
  in
  Gz.Higher.uncompress ~refill ~flush i o
  |> Result.map (fun _metadata -> Buffer.contents r)


let time () = Int32.of_float (Unix.gettimeofday ())

let compress_string ?(level = 4) str =
  let i = De.bigstring_create De.io_buffer_size in
  let o = De.bigstring_create De.io_buffer_size in
  let w = De.Lz77.make_window ~bits:15 in
  let q = De.Queue.create 0x1000 in
  let r = Buffer.create 0x1000 in
  let p = ref 0 in
  let cfg = Gz.Higher.configuration Gz.Unix time in
  let refill buf =
    let len = min (String.length str - !p) De.io_buffer_size in
    Bigstringaf.blit_from_string str ~src_off:!p buf ~dst_off:0 ~len;
    p := !p + len;
    len
  in
  let flush buf len =
    let str = Bigstringaf.substring buf ~off:0 ~len in
    Buffer.add_string r str
  in
  Gz.Higher.compress ~level ~w ~q ~refill ~flush () cfg i o;
  Buffer.contents r


exception GzipError of string

let gzip_h = Cohttp.Header.of_list [ "accept-encoding", "gzip" ]

let extract is_gzipped body =
  if is_gzipped
  then (
    match uncompress_string body with
    | Ok content -> content
    | Error (`Msg error) -> raise (GzipError error))
  else body
