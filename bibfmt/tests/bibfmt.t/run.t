Test basic formatting of BibTeX entries by reading from a file
  $ cat > example.bib << EOF
  > @article {Bravetti_2020,
  > title = "Numerical integration in Celestial Mechanics: a case for contact geometry",volume = "132",ISSN = "1572-9478",
  >   url = "http://dx.doi.org/10.1007/s10569-019-9946-9",
  > DOI="10.1007/s10569-019-9946-9",
  > number="1",journal="Celestial Mechanics and Dynamical Astronomy",
  > publisher     =     "Springer Science and Business Media LLC",
  >   author = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
  > year = "2020", month   =   "jan"
  > }
  > EOF

  $ bibfmt -f example.bib
  @article{Bravetti_2020,
    TITLE     = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    VOLUME    = "132",
    ISSN      = "1572-9478",
    URL       = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI       = "10.1007/s10569-019-9946-9",
    NUMBER    = "1",
    JOURNAL   = "Celestial Mechanics and Dynamical Astronomy",
    PUBLISHER = "Springer Science and Business Media LLC",
    AUTHOR    = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    YEAR      = "2020"
  }

Test formatting BibTeX with braces instead of quotes
  $ cat > braces.bib << EOF
  > @article{Albert_1989,
  >   title = {Le théorème de réduction de Marsden-Weinstein en géométrie cosymplectique et de contact},
  >   volume={6},
  >   ISSN = {0393-0440},
  >   url = {http://dx.doi.org/10.1016/0393-0440(89)90029-6},
  >   DOI={10.1016/0393-0440(89)90029-6},
  >   number={4},
  >   journal={Journal of Geometry and Physics},
  >   publisher={Elsevier BV},
  >   author={Albert, Claude},
  >   year={1989},
  >   pages={627-649}
  > }
  > EOF

  $ bibfmt -f braces.bib
  @article{Albert_1989,
    TITLE     = {Le théorème de réduction de Marsden-Weinstein en géométrie cosymplectique et de contact},
    VOLUME    = {6},
    ISSN      = {0393-0440},
    URL       = {http://dx.doi.org/10.1016/0393-0440(89)90029-6},
    DOI       = {10.1016/0393-0440(89)90029-6},
    NUMBER    = {4},
    JOURNAL   = {Journal of Geometry and Physics},
    PUBLISHER = {Elsevier BV},
    AUTHOR    = {Albert, Claude},
    YEAR      = {1989},
    PAGES     = {627-649}
  }

Test writing to output file
  $ bibfmt -f example.bib -o formatted.bib
  $ cat formatted.bib
  @article{Bravetti_2020,
    TITLE     = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    VOLUME    = "132",
    ISSN      = "1572-9478",
    URL       = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI       = "10.1007/s10569-019-9946-9",
    NUMBER    = "1",
    JOURNAL   = "Celestial Mechanics and Dynamical Astronomy",
    PUBLISHER = "Springer Science and Business Media LLC",
    AUTHOR    = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    YEAR      = "2020"
  }

Test handling of multiple entries
  $ cat > multiple.bib << EOF
  > @article{Entry1,
  >   title = "First Entry",
  >   author = "Author One",
  >   year = 2020
  > }
  > 
  > @book{Entry2,
  >   title = "Second Entry",
  >   author = "Author Two",
  >   year = 2021,
  >   publisher = "Some Publisher"
  > }
  > EOF

  $ bibfmt -f multiple.bib
  @article{Entry1,
    TITLE  = "First Entry",
    AUTHOR = "Author One",
    YEAR   = 2020
  }
  
  @book{Entry2,
    TITLE     = "Second Entry",
    AUTHOR    = "Author Two",
    YEAR      = 2021,
    PUBLISHER = "Some Publisher"
  }

Test handling comments in BibTeX file
  $ cat > comments.bib << EOF
  > % This is a comment
  > @article{CommentTest,
  >   title = "Entry with comments",
  >   author = "Some Author",
  >   % Comment within entry
  >   year = 2022
  > }
  > % Another comment at the end
  > EOF

  $ bibfmt -f comments.bib
  % This is a comment
  @article{CommentTest,
    TITLE  = "Entry with comments",
    AUTHOR = "Some Author",
    % Comment within entry
    YEAR   = 2022
  }
  
  % Another comment at the end

Test handling of entries with special characters
  $ cat > special.bib << EOF
  > @article{SpecialChars,
  >   title = "Übungen zur Quantenmechanik",
  >   author = "Müller, J and Gómez, A",
  >   journal = "Physics Today",
  >   volume = "10",
  >   number = "2",
  >   pages = "23--45",
  >   year = "2022"
  > }
  > EOF

  $ bibfmt -f special.bib
  @article{SpecialChars,
    TITLE   = "Übungen zur Quantenmechanik",
    AUTHOR  = "Müller, J and Gómez, A",
    JOURNAL = "Physics Today",
    VOLUME  = "10",
    NUMBER  = "2",
    PAGES   = "23--45",
    YEAR    = "2022"
  }

Test handling of stdin input
  $ cat example.bib | bibfmt
  @article{Bravetti_2020,
    TITLE     = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    VOLUME    = "132",
    ISSN      = "1572-9478",
    URL       = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI       = "10.1007/s10569-019-9946-9",
    NUMBER    = "1",
    JOURNAL   = "Celestial Mechanics and Dynamical Astronomy",
    PUBLISHER = "Springer Science and Business Media LLC",
    AUTHOR    = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    YEAR      = "2020"
  }

Test parsing of malformed BibTeX (should produce a warning but attempt to return original content)
  $ cat > malformed.bib << EOF
  > @article{Malformed,
  >   title = "Incomplete entry without closing brace"
  > EOF

  $ bibfmt -f malformed.bib
  Warning: Found parsing errors in the BibTeX file:
    - Line 1: Failed to parse entry starting at line 1
  Please check your BibTeX syntax or raise an issue at https://github.com/mseri/doi2bib/issues
  Returning unformatted content.
  @article{Malformed,
    title = "Incomplete entry without closing brace"

Test handling of entries with unquoted values like month abbreviations
  $ cat > unquoted.bib << EOF
  > @article{UnquotedTest,
  >   title = "Test with unquoted values",
  >   author = "Some Author",
  >   journal = "Some Journal",
  >   year = 2023,
  >   month = jan
  > }
  > EOF

  $ bibfmt -f unquoted.bib
  @article{UnquotedTest,
    TITLE   = "Test with unquoted values",
    AUTHOR  = "Some Author",
    JOURNAL = "Some Journal",
    YEAR    = 2023
  }

Test URL unescaping in URL fields
  $ cat > url_escaping.bib << EOF
  > @article{URLEscapeTest,
  >   title = "Test URL Unescaping",
  >   author = "Test Author",
  >   year = 2023,
  >   url = "https://doi.org/10.1234%2Ftest%28example%29%3Cpath%3E%3Aport%3Bquery"
  > }
  > EOF

  $ bibfmt -f url_escaping.bib
  @article{URLEscapeTest,
    TITLE  = "Test URL Unescaping",
    AUTHOR = "Test Author",
    YEAR   = 2023,
    URL    = "https://doi.org/10.1234/test(example)<path>:port;query"
  }

Test URL unescaping with braced values
  $ cat > url_braced.bib << EOF
  > @article{URLBracedTest,
  >   title = {Test URL Unescaping with Braces},
  >   author = {Test Author},
  >   year = 2023,
  >   url = {https://example.com%2Fapi%28v1%29}
  > }
  > EOF

  $ bibfmt -f url_braced.bib
  @article{URLBracedTest,
    TITLE  = {Test URL Unescaping with Braces},
    AUTHOR = {Test Author},
    YEAR   = 2023,
    URL    = {https://example.com/api(v1)}
  }

Test that non-URL fields are not affected by URL unescaping
  $ cat > non_url_fields.bib << EOF
  > @article{NonURLTest,
  >   title = "Title with %2F and %28 percent escapes",
  >   author = "Author %29 with escapes",
  >   note = "Note field %3A with various %3B escapes %3C here %3E",
  >   year = 2023,
  >   url = "https://example.com%2Fpath%28test%29"
  > }
  > EOF

  $ bibfmt -f non_url_fields.bib
  @article{NonURLTest,
    TITLE  = "Title with %2F and %28 percent escapes",
    AUTHOR = "Author %29 with escapes",
    NOTE   = "Note field %3A with various %3B escapes %3C here %3E",
    YEAR   = 2023,
    URL    = "https://example.com/path(test)"
  }

Test comma placement with percent characters in field values
  $ cat > percent_comma.bib << EOF
  > @article{PercentCommaTest,
  >   title = "Field with %percent signs",
  >   author = "Another %field with %signs",
  >   journal = "Journal Name",
  >   year = 2023
  > }
  > EOF

  $ bibfmt -f percent_comma.bib
  @article{PercentCommaTest,
    TITLE   = "Field with %percent signs",
    AUTHOR  = "Another %field with %signs",
    JOURNAL = "Journal Name",
    YEAR    = 2023
  }

Test proper comma handling with comments and percent fields
  $ cat > mixed_percent.bib << EOF
  > @article{MixedPercentTest,
  >   title = "Title with %signs",
  >   % This is a comment that should not get a comma
  >   author = "Author Name",
  >   note = "Note with %more signs",
  >   % Another comment
  >   year = 2023,
  >   url = "https://test.com%2Fpath"
  > }
  > EOF

  $ bibfmt -f mixed_percent.bib
  @article{MixedPercentTest,
    TITLE  = "Title with %signs",
    % This is a comment that should not get a comma
    AUTHOR = "Author Name",
    NOTE   = "Note with %more signs",
    % Another comment
    YEAR   = 2023,
    URL    = "https://test.com/path"
  }

Test URL field with mixed case (should still be unescaped)
  $ cat > url_case.bib << EOF
  > @article{URLCaseTest,
  >   title = "Test URL Case Sensitivity",
  >   author = "Test Author",
  >   URL = "https://example.com%2FPATH%28TEST%29",
  >   Url = "https://another.com%3Aport%2Fpath",
  >   year = 2023
  > }
  > EOF

  $ bibfmt -f url_case.bib
  @article{URLCaseTest,
    TITLE  = "Test URL Case Sensitivity",
    AUTHOR = "Test Author",
    URL    = "https://example.com/PATH(TEST)",
    URL    = "https://another.com:port/path",
    YEAR   = 2023
  }

Test complex URL with all supported escape sequences
  $ cat > url_complete.bib << EOF
  > @article{URLCompleteTest,
  >   title = "Complete URL Escape Test",
  >   author = "Test Author",
  >   year = 2023,
  >   url = "https://dx.doi.org%2F10.1016%2Fj.example.2023.01.001%3Fref%26token%3Aabc%28def%29%3Cghi%3E%3Bjkl"
  > }
  > EOF

  $ bibfmt -f url_complete.bib
  @article{URLCompleteTest,
    TITLE  = "Complete URL Escape Test",
    AUTHOR = "Test Author",
    YEAR   = 2023,
    URL    = "https://dx.doi.org/10.1016/j.example.2023.01.001?ref&token:abc(def)<ghi>;jkl"
  }

Test UTF-8 multi-byte characters in quoted strings
  $ cat > utf8_quoted.bib << EOF
  > @article{UTF8QuotedTest,
  >   title = "Étude des caractères spéciaux: café, naïve, résumé",
  >   author = "Müller, João and García, José",
  >   journal = "Revue Française de Physique",
  >   year = 2023,
  >   note = "Testing UTF-8: ñoël, αβγδε, 中文, русский, العربية"
  > }
  > EOF

  $ bibfmt -f utf8_quoted.bib
  @article{UTF8QuotedTest,
    TITLE   = "Étude des caractères spéciaux: café, naïve, résumé",
    AUTHOR  = "Müller, João and García, José",
    JOURNAL = "Revue Française de Physique",
    YEAR    = 2023,
    NOTE    = "Testing UTF-8: ñoël, αβγδε, 中文, русский, العربية"
  }

Test UTF-8 multi-byte characters in braced strings
  $ cat > utf8_braced.bib << EOF
  > @book{UTF8BracedTest,
  >   title = {Αρχαία Ελληνικά: Ancient Greek Text},
  >   author = {日本語の著者 and Автор на русском},
  >   publisher = {Издательство Unicode},
  >   isbn = {978-3-16-148410-0},
  >   year = {2023},
  >   note = {Mix of scripts: English, Español, Français, Deutsch, العربية, 中文, 日本語, Русский, Ελληνικά}
  > }
  > EOF

  $ bibfmt -f utf8_braced.bib
  @book{UTF8BracedTest,
    TITLE     = {Αρχαία Ελληνικά: Ancient Greek Text},
    AUTHOR    = {日本語の著者 and Автор на русском},
    PUBLISHER = {Издательство Unicode},
    ISBN      = {978-3-16-148410-0},
    YEAR      = {2023},
    NOTE      = {Mix of scripts: English, Español, Français, Deutsch, العربية, 中文, 日本語, Русский, Ελληνικά}
  }

Test UTF-8 characters of different byte lengths
  $ cat > utf8_lengths.bib << EOF
  > @misc{UTF8LengthsTest,
  >   title = "UTF-8 byte length test: à (2-byte), € (3-byte), 𝕌 (4-byte)",
  >   author = "Unicode Specialist",
  >   howpublished = "Various lengths: ñ, ∑, 𝒯, 𝔘, 𝕟, 𝖎, 𝗰, 𝘰, 𝙙, 𝚎",
  >   year = 2023,
  >   note = "Emoji test: 🚀 🌟 📚 🔬 💡 🎯"
  > }
  > EOF

  $ bibfmt -f utf8_lengths.bib
  @misc{UTF8LengthsTest,
    TITLE        = "UTF-8 byte length test: à (2-byte), € (3-byte), 𝕌 (4-byte)",
    AUTHOR       = "Unicode Specialist",
    HOWPUBLISHED = "Various lengths: ñ, ∑, 𝒯, 𝔘, 𝕟, 𝖎, 𝗰, 𝘰, 𝙙, 𝚎",
    YEAR         = 2023,
    NOTE         = "Emoji test: 🚀 🌟 📚 🔬 💡 🎯"
  }

Test mixed UTF-8 with BibTeX special characters and escapes
  $ cat > utf8_mixed.bib << EOF
  > @inproceedings{UTF8MixedTest,
  >   title = "Título español with \"quotes\" and {braces}",
  >   author = "Sánchez, María and O'Connor, Seán",
  >   booktitle = {Proceedings of the 文献学 Conference on "Advanced Topics"},
  >   pages = "123--456",
  >   year = 2023,
  >   note = "Special: \&, \%, \$, plus UTF-8: café, résumé, naïve, piñata",
  >   publisher = "Éditions Académiques & Co."
  > }
  > EOF

  $ bibfmt -f utf8_mixed.bib
  @inproceedings{UTF8MixedTest,
    TITLE     = "Título español with \"quotes\" and {braces}",
    AUTHOR    = "Sánchez, María and O'Connor, Seán",
    BOOKTITLE = {Proceedings of the 文献学 Conference on "Advanced Topics"},
    PAGES     = "123--456",
    YEAR      = 2023,
    NOTE      = "Special: \&, \%, $, plus UTF-8: café, résumé, naïve, piñata",
    PUBLISHER = "Éditions Académiques & Co."
  }
