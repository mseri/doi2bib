let cfg =
  let time () = Int32.of_float (Unix.gettimeofday ()) in
  Gz.Higher.configuration Gz.Unix time
