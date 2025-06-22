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
    title = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    volume = "132",
    ISSN = "1572-9478",
    url = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI = "10.1007/s10569-019-9946-9",
    number = "1",
    journal = "Celestial Mechanics and Dynamical Astronomy",
    publisher = "Springer Science and Business Media LLC",
    author = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    year = "2020",
    month = "jan"
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
    title = "Le théorème de réduction de Marsden-Weinstein en géométrie cosymplectique et de contact",
    volume = "6",
    ISSN = "0393-0440",
    url = "http://dx.doi.org/10.1016/0393-0440(89)90029-6",
    DOI = "10.1016/0393-0440(89)90029-6",
    number = "4",
    journal = "Journal of Geometry and Physics",
    publisher = "Elsevier BV",
    author = "Albert, Claude",
    year = "1989",
    pages = "627-649"
  }

Test writing to output file
  $ bibfmt -f example.bib -o formatted.bib
  $ cat formatted.bib
  @article{Bravetti_2020,
    title = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    volume = "132",
    ISSN = "1572-9478",
    url = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI = "10.1007/s10569-019-9946-9",
    number = "1",
    journal = "Celestial Mechanics and Dynamical Astronomy",
    publisher = "Springer Science and Business Media LLC",
    author = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    year = "2020",
    month = "jan"
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
    title = "First Entry",
    author = "Author One",
    year = 2020
  }
  
  @book{Entry2,
    title = "Second Entry",
    author = "Author Two",
    year = 2021,
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
    title = "Entry with comments",
    author = "Some Author",
    % Comment within entry
    year = 2022
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
    title = "Übungen zur Quantenmechanik",
    author = "Müller, J and Gómez, A",
    journal = "Physics Today",
    volume = "10",
    number = "2",
    pages = "23--45",
    year = "2022"
  }

Test handling of stdin input
  $ cat example.bib | bibfmt
  @article{Bravetti_2020,
    title = "Numerical integration in Celestial Mechanics: a case for contact geometry",
    volume = "132",
    ISSN = "1572-9478",
    url = "http://dx.doi.org/10.1007/s10569-019-9946-9",
    DOI = "10.1007/s10569-019-9946-9",
    number = "1",
    journal = "Celestial Mechanics and Dynamical Astronomy",
    publisher = "Springer Science and Business Media LLC",
    author = "Bravetti, Alessandro and Seri, Marcello and Vermeeren, Mats and Zadra, Federico",
    year = "2020",
    month = "jan"
  }

Test parsing of malformed BibTeX (should produce a warning but attempt to return original content)
  $ cat > malformed.bib << EOF
  > @article{Malformed,
  >   title = "Incomplete entry without closing brace"
  > EOF

  $ bibfmt -f malformed.bib
  Warning: we are not able to pretty print the specified bibtex file please raise an issue at https://github.com/mseri/doi2bib/issues
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
    title = "Test with unquoted values",
    author = "Some Author",
    journal = "Some Journal",
    year = 2023,
    month = "jan"
  }
