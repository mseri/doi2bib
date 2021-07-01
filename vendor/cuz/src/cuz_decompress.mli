val inflate_string_de : string -> (string, [> `Msg of string ]) result
val deflate_string_de : string -> string
val inflate_string_gz : string -> (string, [> `Msg of string ]) result
val deflate_string_gz : cfg:unit Gz.Higher.configuration -> ?level:int -> string -> string
