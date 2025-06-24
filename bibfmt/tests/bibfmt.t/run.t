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
    title     = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    volume    = "132",
    ISSN      = "1572-9478",
    url       = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI       = "10.1007/s10569-019-9946-9",
    number    = "1",
    journal   = "Celestial Mechanics and Dynamical Astronomy",
    publisher = "Springer Science and Business Media LLC",
    author    = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    year      = "2020",
    month     = "jan"
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
    title     = {Le théorème de réduction de Marsden-Weinstein en géométrie cosymplectique et de contact},
    volume    = {6},
    ISSN      = {0393-0440},
    url       = {http://dx.doi.org/10.1016/0393-0440(89)90029-6},
    DOI       = {10.1016/0393-0440(89)90029-6},
    number    = {4},
    journal   = {Journal of Geometry and Physics},
    publisher = {Elsevier BV},
    author    = {Albert, Claude},
    year      = {1989},
    pages     = {627-649}
  }

Test writing to output file
  $ bibfmt -f example.bib -o formatted.bib
  $ cat formatted.bib
  @article{Bravetti_2020,
    title     = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    volume    = "132",
    ISSN      = "1572-9478",
    url       = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI       = "10.1007/s10569-019-9946-9",
    number    = "1",
    journal   = "Celestial Mechanics and Dynamical Astronomy",
    publisher = "Springer Science and Business Media LLC",
    author    = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    year      = "2020",
    month     = "jan"
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
    title  = "First Entry",
    author = "Author One",
    year   = 2020
  }
  
  @book{Entry2,
    title     = "Second Entry",
    author    = "Author Two",
    year      = 2021,
    publisher = "Some Publisher"
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
    title  = "Entry with comments",
    author = "Some Author",
    % Comment within entry
    year   = 2022
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
    title   = "Übungen zur Quantenmechanik",
    author  = "Müller, J and Gómez, A",
    journal = "Physics Today",
    volume  = "10",
    number  = "2",
    pages   = "23--45",
    year    = "2022"
  }

Test handling of stdin input
  $ cat example.bib | bibfmt
  @article{Bravetti_2020,
    title     = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    volume    = "132",
    ISSN      = "1572-9478",
    url       = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI       = "10.1007/s10569-019-9946-9",
    number    = "1",
    journal   = "Celestial Mechanics and Dynamical Astronomy",
    publisher = "Springer Science and Business Media LLC",
    author    = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    year      = "2020",
    month     = "jan"
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
    title   = "Test with unquoted values",
    author  = "Some Author",
    journal = "Some Journal",
    year    = 2023,
    month   = {jan}
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
    title  = "Test URL Unescaping",
    author = "Test Author",
    year   = 2023,
    url    = "https://doi.org/10.1234/test(example)<path>:port;query"
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
    title  = {Test URL Unescaping with Braces},
    author = {Test Author},
    year   = 2023,
    url    = {https://example.com/api(v1)}
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
    title  = "Title with %2F and %28 percent escapes",
    author = "Author %29 with escapes",
    note   = "Note field %3A with various %3B escapes %3C here %3E",
    year   = 2023,
    url    = "https://example.com/path(test)"
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
    title   = "Field with %percent signs",
    author  = "Another %field with %signs",
    journal = "Journal Name",
    year    = 2023
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
    title  = "Title with %signs",
    % This is a comment that should not get a comma
    author = "Author Name",
    note   = "Note with %more signs",
    % Another comment
    year   = 2023,
    url    = "https://test.com/path"
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
    title  = "Test URL Case Sensitivity",
    author = "Test Author",
    URL    = "https://example.com/PATH(TEST)",
    Url    = "https://another.com:port/path",
    year   = 2023
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
    title  = "Complete URL Escape Test",
    author = "Test Author",
    year   = 2023,
    url    = "https://dx.doi.org/10.1016/j.example.2023.01.001?ref&token:abc(def)<ghi>;jkl"
  }
