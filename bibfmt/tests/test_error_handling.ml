(* Test error handling functionality for BibTeX parsing *)

let test_valid_bibtex () =
  let input =
    {|@article{test1,
  title = {Valid Article},
  author = {John Doe}
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  assert (List.length result.items = 1);
  assert (List.length result.errors = 0);
  assert (not (Bibtex.has_parse_errors result));
  Printf.printf "✓ Valid BibTeX parsed correctly\n"

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
  Printf.printf "Parsed %d items with %d errors\n" (List.length result.items)
    (List.length result.errors);
  assert (List.length result.items >= 1);
  (* Should parse at least some valid entries *)
  assert (List.length result.errors >= 1);
  (* Should have at least one error *)
  assert (Bibtex.has_parse_errors result);
  Printf.printf "✓ Malformed BibTeX handled correctly\n"

let test_completely_invalid_input () =
  let input =
    {|This is not BibTeX at all!
Just some random text.
@invalid_entry_without_proper_format
More random content.|}
  in
  let result = Bibtex.parse_bibtex_with_errors input in
  Printf.printf "Completely invalid input: %d items, %d errors\n"
    (List.length result.items)
    (List.length result.errors);
  assert (List.length result.items = 0);
  (* Should parse no valid entries *)
  assert (List.length result.errors >= 1);
  (* Should have errors *)
  Printf.printf "✓ Invalid input handled correctly\n"

let test_backward_compatibility () =
  let input =
    {|@article{test,
  title = {Test Article},
  author = {Test Author}
}|}
  in
  let old_result = Bibtex.parse_bibtex input in
  let new_result = Bibtex.parse_bibtex_with_errors input in
  assert (List.length old_result = List.length new_result.items);
  assert (List.length new_result.errors = 0);
  Printf.printf "✓ Backward compatibility maintained\n"

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
  assert (List.length errors >= 1);
  List.iter
    (fun error ->
      Printf.printf "Error at line %d: %s\n" error.Bibtex.line error.message;
      assert (error.line >= 1);
      assert (String.length error.message > 0))
    errors;
  Printf.printf "✓ Error details provided correctly\n"

let test_utf8_handling () =
  (* Test various UTF-8 characters in quoted strings *)
  let input_quoted =
    {|@article{utf8_test1,
  title = "Étude des caractères spéciaux: ñoël, 中文, русский, العربية",
  author = "Müller, João and Гомес, أحمد",
  journal = "Revue Française 文献 مجلة",
  year = 2023
}|}
  in
  let result = Bibtex.parse_bibtex_with_errors input_quoted in
  assert (List.length result.items = 1);
  assert (List.length result.errors = 0);
  Printf.printf "✓ UTF-8 characters in quoted strings handled correctly\n";

  (* Test various UTF-8 characters in braced strings *)
  let input_braced =
    {|@book{utf8_test2,
  title = {Αρχαία Ελληνικά: αβγδε},
  author = {日本語の著者},
  publisher = {Издательство на русском},
  isbn = {978-3-16-148410-0},
  year = {2023}
}|}
  in
  let result2 = Bibtex.parse_bibtex_with_errors input_braced in
  assert (List.length result2.items = 1);
  assert (List.length result2.errors = 0);
  Printf.printf "✓ UTF-8 characters in braced strings handled correctly\n";

  (* Test mixed UTF-8 with special BibTeX characters *)
  let input_mixed =
    {|@inproceedings{utf8_test3,
  title = "Título con acentos: ñáéíóú",
  author = "García, José and Müller, Jürgen",
  booktitle = {Proceedings of the 42nd Conference on "Advanced Topics"},
  pages = "123--456",
  year = 2023,
  note = "Special chars: {ü}, \"ä\", \\&, \\%, \\$"
}|}
  in
  let result3 = Bibtex.parse_bibtex_with_errors input_mixed in
  assert (List.length result3.items = 1);
  assert (List.length result3.errors = 0);
  Printf.printf
    "✓ Mixed UTF-8 with BibTeX special characters handled correctly\n";

  (* Test UTF-8 characters at different byte lengths *)
  let input_multilength =
    {|@misc{utf8_test4,
  title = "Test: à (2-byte), € (3-byte), 𝕌 (4-byte)",
  author = "Unicode Tester",
  howpublished = "Testing UTF-8: café, naïve, résumé, piñata",
  year = 2023
}|}
  in
  let result4 = Bibtex.parse_bibtex_with_errors input_multilength in
  assert (List.length result4.items = 1);
  assert (List.length result4.errors = 0);
  Printf.printf
    "✓ UTF-8 characters of different byte lengths handled correctly\n"

let run_tests () =
  Printf.printf "Running BibTeX error handling tests...\n\n";
  test_valid_bibtex ();
  test_malformed_bibtex ();
  test_completely_invalid_input ();
  test_backward_compatibility ();
  test_error_details ();
  test_utf8_handling ();
  Printf.printf "\n✓✓✓ All tests passed!\n"

let () = run_tests ()
