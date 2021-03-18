open Astring
open Rresult

type error =
  | Truncated of string
  | Invalid_format
  | Compression_error of string
  | Size of {got: int; expected: int}
  | Checksum

let pp_error fmt error =
  match error with
  | Truncated content ->
      Format.fprintf fmt "Truncated content after %d bytes"
        (String.length content)
  | Invalid_format -> Format.fprintf fmt "Invalid gzip format"
  | Compression_error msg -> Format.fprintf fmt "Compression error: %s" msg
  | Size {got; expected} ->
      Format.fprintf fmt
        "Size mismatch after decompression: got %d, expected %d" got expected
  | Checksum -> Format.fprintf fmt "Invalid checksum after decompression"


let pp_gzip_error fmt wrapped =
  let `Gzip error = wrapped in
  pp_error fmt error


let error e = R.error (`Gzip e)

module Z = struct
  type error = Truncated of string | Compression_error of string

  let pp_error fmt error =
    match error with
    | Truncated content ->
        Format.fprintf fmt "Truncated content after %d bytes"
          (String.length content)
    | Compression_error msg -> Format.fprintf fmt "Compression error: %s" msg


  let pp_zlib_error fmt wrapped =
    let `Zlib error = wrapped in
    pp_error fmt error


  let error e = R.error (`Zlib e)

  let compress_zlib ?level ?(header= false) input output =
    let pos = ref 0 in
    let length = String.length input in
    let feed buf =
      let bytes = min (Bytes.length buf) (length - !pos) in
      Bytes.blit_string input !pos buf 0 bytes ;
      pos := !pos + bytes ;
      bytes
    in
    Zlib.compress ?level ~header feed output


  let uncompress_zlib ?(header= false) input output =
    let pos = ref 0 in
    let length = String.length input in
    let feed buf =
      let bytes = min (Bytes.length buf) (length - !pos) in
      Bytes.blit_string input !pos buf 0 bytes ;
      pos := !pos + bytes ;
      bytes
    in
    Zlib.uncompress ~header feed output


  let compress ?level ?header input =
    let compressed = Buffer.create 1_024 in
    let output buffer length =
      Buffer.add_subbytes compressed buffer 0 length
    in
    compress_zlib ?level ?header input output ;
    Buffer.contents compressed


  let decompress ?header ?(max_size= Sys.max_string_length) input =
    let size = ref 0 in
    let uncompressed = Buffer.create 1_024 in
    let output buffer length =
      size := !size + length ;
      if !size < 0 then
        invalid_arg "Ezgzip: output larger than max string length" ;
      if !size > max_size then raise Exit
      else Buffer.add_subbytes uncompressed buffer 0 length
    in
    try
      uncompress_zlib ?header input output ;
      Ok (Buffer.contents uncompressed)
    with
    | Exit -> error (Truncated (Buffer.contents uncompressed))
    | Zlib.Error (func, msg) ->
        let message = Format.asprintf "in %s: %s" func msg in
        error (Compression_error message)
end

let id1_id2 = "\x1f\x8b"

(* XXX: Hard-coded gzip header may not be the best idea... *)
let header =
  let compression_method = "\x08" in
  let flags1 = "\x00" in
  let time = "\x00\x00\x00\x00" in
  let flags2 = "\x00" in
  let os = "\xff" in
  String.concat [id1_id2; compression_method; flags1; time; flags2; os]


let header_size =
  let bytes = String.length header in
  assert (bytes = 10);
  bytes


let footer_size = 8

let compress ?level raw =
  ( match level with
  | None -> ()
  | Some i ->
      if i < 0 || i > 9 then
        invalid_arg
          (strf "Ezgzip.compress: invalid level %d - must be between 0 and 9" i)
  ) ;
  let int32_to_bytestring i =
    let buf = Bytes.create 4 in
    EndianString.LittleEndian.set_int32 buf 0 i ;
    Bytes.to_string buf
  in
  let compressed = Z.compress ?level raw in
  let length = String.length raw in
  let crc32 = Zlib.update_crc_string 0l raw 0 length in
  let crc32_checksum = int32_to_bytestring crc32 in
  let original_size =
    int32_to_bytestring (Int32.of_int (length mod 0x1_0000_0000))
  in
  String.concat [header; compressed; crc32_checksum; original_size]


type flags = {text: bool; crc16: bool; extra: bool; name: bool; comment: bool}

let flags_of_int i =
  let bit x = i land x = x in
  if bit 32 || bit 64 || bit 128 then error Invalid_format
  else
    Ok {text= bit 1; crc16= bit 2; extra= bit 4; name= bit 8; comment= bit 16}


type t = {compressed: string; crc32: int32; original_size: int}

let extra_content_length raw flags =
  let extra_bytes = ref 0 in
  let offset () = !extra_bytes + header_size in
  ( if flags.extra then
      let xlen = EndianString.LittleEndian.get_int16 raw (offset ()) in
      extra_bytes := !extra_bytes + xlen + 2 ) ;
  ( if flags.name then
      let sub = String.sub_with_range ~first:(offset ()) raw in
      let name = String.Sub.take ~sat:(fun c -> c <> '\x00') sub in
      extra_bytes := !extra_bytes + String.Sub.length name + 1 ) ;
  ( if flags.comment then
      let sub = String.sub_with_range ~first:(offset ()) raw in
      let comment = String.Sub.take ~sat:(fun c -> c <> '\x00') sub in
      extra_bytes := !extra_bytes + String.Sub.length comment + 1 ) ;
  if flags.crc16 then extra_bytes := !extra_bytes + 2 ;
  !extra_bytes


let parse_gzip_bytes raw =
  (* XXX: Ignoring most of the header may not be the best idea... *)
  let ( >>= ) = R.( >>= ) in
  (* Make sure we have enough bytes to work with *)
  ( if String.length raw < header_size + footer_size then error Invalid_format
  else Ok () )
  >>= fun () ->
  (* Check magic bytes *)
  (if String.is_prefix ~affix:id1_id2 raw then Ok () else error Invalid_format)
  >>= fun () ->
  (* Parse flags *)
  flags_of_int (Char.to_int raw.[3])
  >>= fun flags ->
  (* Calculate the extra content size so we can skip it *)
  ( match extra_content_length raw flags with
  | length -> Ok length
  | exception Exit -> error Invalid_format )
  >>= fun extra_size ->
  (* Make sure we actually have data left over *)
  let compressed_length =
    String.length raw - header_size - footer_size - extra_size
  in
  (if compressed_length >= 0 then Ok () else error Invalid_format)
  >>= fun () ->
  let compressed =
    String.with_range ~first:(header_size + extra_size) ~len:compressed_length
      raw
  in
  let crc32 =
    EndianString.LittleEndian.get_int32 raw (String.length raw - 4 - 4)
  in
  let original_size =
    let size =
      EndianString.LittleEndian.get_int32 raw (String.length raw - 4)
    in
    Int32.to_int size land 0xffff_ffff
  in
  Ok {compressed; crc32; original_size}


let decompress ?(ignore_size= false) ?(ignore_checksum= false) ?max_size raw =
  let ( >>= ) = R.( >>= ) in
  parse_gzip_bytes raw
  >>= fun {compressed; crc32; original_size} ->
  ( match Z.decompress ?max_size compressed with
  | Ok uncompressed -> Ok uncompressed
  | Error `Zlib Truncated uncompressed -> error (Truncated uncompressed)
  | Error `Zlib Compression_error message -> error (Compression_error message)
  )
  >>= fun uncompressed ->
  if not ignore_size
     && String.length uncompressed mod 0x1_0000_0000 <> original_size
  then
    R.error
      (`Gzip (Size {got= String.length uncompressed; expected= original_size}))
  else
    let crc32_calculated () =
      Zlib.update_crc_string 0l uncompressed 0 (String.length uncompressed)
    in
    if not ignore_checksum && crc32_calculated () <> crc32 then
      R.error (`Gzip Checksum)
    else Ok uncompressed
