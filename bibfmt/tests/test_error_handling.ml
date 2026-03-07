(* Test error handling functionality for BibTeX parsing *)

let test_valid_bibtex () =
  let input =
    {|@article{test1,
  title = {Valid Article},
  author = {John Doe}
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check int) "should parse 1 item" 1 (List.length result.items);
  Alcotest.(check int) "should have 0 errors" 0 (List.length result.errors);
  Alcotest.(check bool) "has_parse_errors should be false" false (Bibtex.has_parse_errors result)

let test_malformed_bibtex () =
  let input =
    {|@article{test1,
  title = {Valid Article},
  author = {John Doe}
}

@article{test2,
  title = {Malformed Entry},
  author = {Jane Smith}

@book{test3,
  title = {Another Valid Book},
  author = {Bob Wilson}
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check bool) "should parse at least one item" true (List.length result.items >= 1);
  Alcotest.(check bool) "should have at least one error" true (List.length result.errors >= 1);
  Alcotest.(check bool) "has_parse_errors should be true" true (Bibtex.has_parse_errors result)

let test_completely_invalid_input () =
  let input =
    {|This is not BibTeX at all!
Just some random text.
@invalid_entry_without_proper_format
More random content.|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check int) "should parse no valid entries" 0 (List.length result.items);
  Alcotest.(check bool) "should have errors" true (List.length result.errors >= 1)

let test_backward_compatibility () =
  let input =
    {|@article{test,
  title = {Test Article},
  author = {Test Author}
}|}
  in
  let old_result = Bibtex.parse_bibtex input in
  let new_result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check int) "old and new API should return same count" (List.length old_result) (List.length new_result.items);
  Alcotest.(check int) "new API should have no errors on valid input" 0 (List.length new_result.errors)

let test_error_details () =
  let input =
    {|@article{test1,
  title = {Valid Entry}
}

@article{malformed
  title = {Missing closing brace}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  let errors = Bibtex.get_parse_errors result in
  Alcotest.(check bool) "should have at least one error" true (List.length errors >= 1);
  List.iter
    (fun error ->
      Alcotest.(check bool) "error line should be >= 1" true (error.Bibtex.line >= 1);
      Alcotest.(check bool) "error message should not be empty" true (String.length error.message > 0))
    errors

let test_utf8_quoted_strings () =
  let input =
    {|@article{utf8_test1,
  title = "Étude des caractères spéciaux: ñoël, 中文, русский, العربية",
  author = "Müller, João and Гомес, أحمد",
  journal = "Revue Française 文献 مجلة",
  year = 2023
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check int) "should parse 1 item" 1 (List.length result.items);
  Alcotest.(check int) "should have 0 errors" 0 (List.length result.errors)

let test_utf8_braced_strings () =
  let input =
    {|@book{utf8_test2,
  title = {Αρχαία Ελληνικά: αβγδε},
  author = {日本語の著者},
  publisher = {Издательство на русском},
  isbn = {978-3-16-148410-0},
  year = {2023}
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check int) "should parse 1 item" 1 (List.length result.items);
  Alcotest.(check int) "should have 0 errors" 0 (List.length result.errors)

let test_utf8_mixed () =
  let input =
    {|@inproceedings{utf8_test3,
  title = "Título con acentos: ñáéíóú",
  author = "García, José and Müller, Jürgen",
  booktitle = {Proceedings of the 42nd Conference on "Advanced Topics"},
  pages = "123--456",
  year = 2023,
  note = "Special chars: {ü}, \"ä\", \\&, \\%, \\$"
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check int) "should parse 1 item" 1 (List.length result.items);
  Alcotest.(check int) "should have 0 errors" 0 (List.length result.errors)

let test_utf8_multilength () =
  let input =
    {|@misc{utf8_test4,
  title = "Test: à (2-byte), € (3-byte), 𝕌 (4-byte)",
  author = "Unicode Tester",
  howpublished = "Testing UTF-8: café, naïve, résumé, piñata",
  year = 2023
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Alcotest.(check int) "should parse 1 item" 1 (List.length result.items);
  Alcotest.(check int) "should have 0 errors" 0 (List.length result.errors)

let () =
  let open Alcotest in
  run "BibTeX Error Handling"
    [
      ("parsing",
       [
         test_case "valid bibtex" `Quick test_valid_bibtex;
         test_case "malformed bibtex" `Quick test_malformed_bibtex;
         test_case "completely invalid input" `Quick test_completely_invalid_input;
         test_case "backward compatibility" `Quick test_backward_compatibility;
         test_case "error details" `Quick test_error_details;
       ]);
      ("utf8",
       [
         test_case "quoted strings" `Quick test_utf8_quoted_strings;
         test_case "braced strings" `Quick test_utf8_braced_strings;
         test_case "mixed utf8" `Quick test_utf8_mixed;
         test_case "multilength utf8" `Quick test_utf8_multilength;
       ]);
    ]
