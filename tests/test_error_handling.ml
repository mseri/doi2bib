(* Test error handling functionality for BibTeX parsing *)

let test_valid_bibtex () =
  let input =
    {|@article{test1,
  title = {Valid Article},
  author = {John Doe}
}|}
  in
  let result = Doi2bib.Bibtex.parse_bibtex_with_errors input in
  assert (List.length result.items = 1);
  assert (List.length result.errors = 0);
  assert (not (Doi2bib.Bibtex.has_parse_errors result));
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
  let result = Doi2bib.Bibtex.parse_bibtex_with_errors input in
  Printf.printf "Parsed %d items with %d errors\n" (List.length result.items)
    (List.length result.errors);
  assert (List.length result.items >= 1);
  (* Should parse at least some valid entries *)
  assert (List.length result.errors >= 1);
  (* Should have at least one error *)
  assert (Doi2bib.Bibtex.has_parse_errors result);
  Printf.printf "✓ Malformed BibTeX handled correctly\n"

let test_completely_invalid_input () =
  let input =
    {|This is not BibTeX at all!
Just some random text.
@invalid_entry_without_proper_format
More random content.|}
  in
  let result = Doi2bib.Bibtex.parse_bibtex_with_errors input in
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
  let old_result = Doi2bib.Bibtex.parse_bibtex input in
  let new_result = Doi2bib.Bibtex.parse_bibtex_with_errors input in
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
  let result = Doi2bib.Bibtex.parse_bibtex_with_errors input in
  let errors = Doi2bib.Bibtex.get_parse_errors result in
  assert (List.length errors >= 1);
  List.iter
    (fun error ->
      Printf.printf "Error at position %d: %s\n" error.Doi2bib.Bibtex.position
        error.message;
      assert (error.position >= 0);
      assert (String.length error.message > 0))
    errors;
  Printf.printf "✓ Error details provided correctly\n"

let run_tests () =
  Printf.printf "Running BibTeX error handling tests...\n\n";
  test_valid_bibtex ();
  test_malformed_bibtex ();
  test_completely_invalid_input ();
  test_backward_compatibility ();
  test_error_details ();
  Printf.printf "\n✅ All tests passed!\n"

let () = run_tests ()
