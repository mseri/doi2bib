let basic_predefined_checks () =
  let gzip_error = Alcotest.testable Ezgzip.pp_gzip_error (fun _ _ -> true) in
  Alcotest.(check (result string gzip_error))
    "Round trip - known good" (Ok "hello world")
    (Ezgzip.compress "hello world" |> Ezgzip.decompress) ;
  Alcotest.(check (result string gzip_error))
    "Known bad" (Error (`Gzip (Compression_error "placeholder message")))
    (Ezgzip.decompress "probably not gzip") ;
  let big = String.make 1_000_000 'x' in
  Alcotest.(check (result string gzip_error))
    "Big-ish" (Ok big)
    (Ezgzip.compress big |> Ezgzip.decompress) ;
  ()


let round_trip s =
  let compressed = Ezgzip.compress s in
  match Ezgzip.decompress compressed with
  | Error err ->
      Alcotest.failf "Failed to decompress: %a" Ezgzip.pp_gzip_error err
  | Ok s' -> Alcotest.equal Alcotest.string s s'


let round_trip_random_cases name count () =
  QCheck.Test.make ~count ~name QCheck.string round_trip
  |> QCheck.Test.check_exn


let predefined_tests = [("predefined cases", `Quick, basic_predefined_checks)]

let quickcheck_tests =
  [ ( "round-trip"
    , `Quick
    , round_trip_random_cases "round-trip quickcheck" 1_000 ) ]


let () =
  Alcotest.run "ezgzip"
    [("basic", predefined_tests); ("quickcheck", quickcheck_tests)]
