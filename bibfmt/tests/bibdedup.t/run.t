Test default deduplication using title, author, and year
  $ cat > sample.bib << EOF
  > @article{einstein1905,
  >   author = {Albert Einstein},
  >   title = {On the Electrodynamics of Moving Bodies},
  >   journal = {Annalen der Physik},
  >   year = {1905},
  >   volume = {17},
  >   pages = {891--921}
  > }
  > 
  > @article{einstein1905_duplicate,
  >   author = {Albert  Einstein},
  >   title = {On the Electrodynamics of Moving Bodies},
  >   journal = {Annalen der Physik},
  >   year = {1905},
  >   volume = {17},
  >   pages = {891-921},
  >   doi = {10.1002/andp.19053221004}
  > }
  > 
  > @article{feynman1949,
  >   author = {Richard P. Feynman},
  >   title = {The Theory of Positrons},
  >   journal = {Physical Review},
  >   year = {1949},
  >   volume = {76},
  >   pages = {749--759}
  > }
  > 
  > @article{einstein1905_another,
  >   author = {A. Einstein},
  >   title = {On the Electrodynamics of Moving Bodies},
  >   journal = {Ann. Phys.},
  >   year = {1905},
  >   volume = {17}
  > }
  > EOF

  $ bibdedup sample.bib
  Using deduplication keys: [title; author; year]
  Reading 1 file(s)...
    Read sample.bib
  Parsing BibTeX entries...
  Parsed 4 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 4 → 3 entries
  @article{einstein1905,
    DOI     = {10.1002/andp.19053221004},
    TITLE   = {On the Electrodynamics of Moving Bodies},
    JOURNAL = {Annalen der Physik},
    VOLUME  = {17},
    YEAR    = {1905},
    AUTHOR  = {Albert Einstein},
    PAGES   = {891--921}
  }
  
  @article{einstein1905_another,
    AUTHOR  = {A. Einstein},
    TITLE   = {On the Electrodynamics of Moving Bodies},
    JOURNAL = {Ann. Phys.},
    YEAR    = {1905},
    VOLUME  = {17}
  }
  
  @article{feynman1949,
    AUTHOR  = {Richard P. Feynman},
    TITLE   = {The Theory of Positrons},
    JOURNAL = {Physical Review},
    YEAR    = {1949},
    VOLUME  = {76},
    PAGES   = {749--759}
  }

Test custom keys for duplicate detection (title and year only)
  $ bibdedup --keys title,year sample.bib
  Using deduplication keys: [title; year]
  Reading 1 file(s)...
    Read sample.bib
  Parsing BibTeX entries...
  Parsed 4 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 4 → 2 entries
  @article{einstein1905,
    DOI     = {10.1002/andp.19053221004},
    TITLE   = {On the Electrodynamics of Moving Bodies},
    JOURNAL = {Annalen der Physik},
    VOLUME  = {17},
    YEAR    = {1905},
    AUTHOR  = {Albert Einstein},
    PAGES   = {891--921}
  }
  
  @article{feynman1949,
    AUTHOR  = {Richard P. Feynman},
    TITLE   = {The Theory of Positrons},
    JOURNAL = {Physical Review},
    YEAR    = {1949},
    VOLUME  = {76},
    PAGES   = {749--759}
  }

Test DOI-based deduplication
  $ cat > doi_test.bib << EOF
  > @article{paper1,
  >   author = {John Doe},
  >   title = {Research Paper},
  >   year = {2020},
  >   doi = {10.1234/example.2020.001}
  > }
  > 
  > @article{paper2,
  >   author = {John Doe and Jane Smith},
  >   title = {Research Paper - Extended Version},
  >   year = {2020},
  >   journal = {Nature},
  >   doi = {10.1234/example.2020.001}
  > }
  > 
  > @article{paper3,
  >   author = {Bob Wilson},
  >   title = {Different Research},
  >   year = {2021},
  >   doi = {10.1234/different.2021.001}
  > }
  > EOF

  $ bibdedup --keys doi doi_test.bib
  Using deduplication keys: [doi]
  Reading 1 file(s)...
    Read doi_test.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 3 → 2 entries
  @article{paper1,
    DOI     = {10.1234/example.2020.001},
    TITLE   = {Research Paper},
    JOURNAL = {Nature},
    YEAR    = {2020},
    AUTHOR  = {John Doe}
  }
  
  @article{paper3,
    AUTHOR = {Bob Wilson},
    TITLE  = {Different Research},
    YEAR   = {2021},
    DOI    = {10.1234/different.2021.001}
  }

Test no duplicates case
  $ cat > unique_entries.bib << EOF
  > @article{unique1,
  >   author = {Author One},
  >   title = {First Unique Paper},
  >   year = {2020}
  > }
  > 
  > @article{unique2,
  >   author = {Author Two},
  >   title = {Second Unique Paper},
  >   year = {2021}
  > }
  > 
  > @book{unique3,
  >   author = {Author Three},
  >   title = {Unique Book},
  >   year = {2022},
  >   publisher = {Academic Press}
  > }
  > EOF

  $ bibdedup unique_entries.bib
  Using deduplication keys: [title; author; year]
  Reading 1 file(s)...
    Read unique_entries.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  No duplicates found.
  
  Deduplication complete: 3 → 3 entries
  @article{unique1,
    AUTHOR = {Author One},
    TITLE  = {First Unique Paper},
    YEAR   = {2020}
  }
  
  @article{unique2,
    AUTHOR = {Author Two},
    TITLE  = {Second Unique Paper},
    YEAR   = {2021}
  }
  
  @book{unique3,
    AUTHOR    = {Author Three},
    TITLE     = {Unique Book},
    YEAR      = {2022},
    PUBLISHER = {Academic Press}
  }

Test whitespace and case normalization
  $ cat > normalization_test.bib << EOF
  > @article{test1,
  >   author = { John   Doe },
  >   title = { Machine    Learning },
  >   year = {2020}
  > }
  > 
  > @article{test2,
  >   author = {john doe},
  >   title = {MACHINE LEARNING},
  >   year = {2020},
  >   journal = {AI Journal}
  > }
  > 
  > @article{test3,
  >   author = {Jane Smith},
  >   title = {Deep Learning},
  >   year = {2020}
  > }
  > EOF

  $ bibdedup normalization_test.bib
  Using deduplication keys: [title; author; year]
  Reading 1 file(s)...
    Read normalization_test.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 3 → 2 entries
  @article{test1,
    TITLE   = {Machine    Learning},
    JOURNAL = {AI Journal},
    YEAR    = {2020},
    AUTHOR  = {John   Doe}
  }
  
  @article{test3,
    AUTHOR = {Jane Smith},
    TITLE  = {Deep Learning},
    YEAR   = {2020}
  }

Test multiple file deduplication
  $ cat > multi1.bib << EOF
  > @article{shared1,
  >   author = {Alice Brown},
  >   title = {Quantum Computing},
  >   year = {2023}
  > }
  > 
  > @article{file1_unique,
  >   author = {Bob Green},
  >   title = {Classical Computing},
  >   year = {2023}
  > }
  > EOF

  $ cat > multi2.bib << EOF
  > @article{shared1,
  >   author = {Alice Brown},
  >   title = {Quantum Computing},
  >   year = {2023},
  >   journal = {Nature Quantum}
  > }
  > 
  > @article{file2_unique,
  >   author = {Charlie Red},
  >   title = {Hybrid Computing},
  >   year = {2023}
  > }
  > EOF

  $ bibdedup multi1.bib multi2.bib
  Using deduplication keys: [title; author; year]
  Reading 2 file(s)...
    Read multi1.bib
    Read multi2.bib
  Parsing BibTeX entries...
  Parsed 4 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 4 → 3 entries
  @article{file1_unique,
    AUTHOR = {Bob Green},
    TITLE  = {Classical Computing},
    YEAR   = {2023}
  }
  
  @article{file2_unique,
    AUTHOR = {Charlie Red},
    TITLE  = {Hybrid Computing},
    YEAR   = {2023}
  }
  
  @article{shared1,
    TITLE   = {Quantum Computing},
    JOURNAL = {Nature Quantum},
    YEAR    = {2023},
    AUTHOR  = {Alice Brown}
  }

Test handling of missing fields in deduplication keys
  $ cat > missing_fields.bib << EOF
  > @article{complete,
  >   author = {Complete Author},
  >   title = {Complete Title},
  >   year = {2023}
  > }
  > 
  > @article{missing_author,
  >   title = {Complete Title},
  >   year = {2023},
  >   journal = {Some Journal}
  > }
  > 
  > @article{missing_year,
  >   author = {Complete Author},
  >   title = {Complete Title},
  >   note = {No year specified}
  > }
  > EOF

  $ bibdedup missing_fields.bib
  Using deduplication keys: [title; author; year]
  Reading 1 file(s)...
    Read missing_fields.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  No duplicates found.
  
  Deduplication complete: 3 → 3 entries
  @article{complete,
    AUTHOR = {Complete Author},
    TITLE  = {Complete Title},
    YEAR   = {2023}
  }
  
  @article{missing_author,
    TITLE   = {Complete Title},
    YEAR    = {2023},
    JOURNAL = {Some Journal}
  }
  
  @article{missing_year,
    AUTHOR = {Complete Author},
    TITLE  = {Complete Title},
    NOTE   = {No year specified}
  }

Test output to file with multiple inputs
  $ bibdedup --keys author,title multi1.bib multi2.bib -o merged_output.bib
  Using deduplication keys: [author; title]
  Reading 2 file(s)...
    Read multi1.bib
    Read multi2.bib
  Parsing BibTeX entries...
  Parsed 4 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 4 → 3 entries
  Output written to merged_output.bib

  $ cat merged_output.bib
  @article{file1_unique,
    AUTHOR = {Bob Green},
    TITLE  = {Classical Computing},
    YEAR   = {2023}
  }
  
  @article{file2_unique,
    AUTHOR = {Charlie Red},
    TITLE  = {Hybrid Computing},
    YEAR   = {2023}
  }
  
  @article{shared1,
    TITLE   = {Quantum Computing},
    JOURNAL = {Nature Quantum},
    YEAR    = {2023},
    AUTHOR  = {Alice Brown}
  }

Test handling of malformed BibTeX during deduplication
  $ cat > malformed_dedup.bib << EOF
  > @article{good_entry,
  >   author = {Good Author},
  >   title = {Good Title},
  >   year = {2023}
  > }
  > 
  > @article{incomplete_entry,
  >   author = {Bad Author},
  >   title = {Missing closing brace"
  > 
  > @article{another_good,
  >   author = {Another Author},
  >   title = {Another Title},
  >   year = {2023}
  > }
  > EOF

  $ bibdedup malformed_dedup.bib
  Using deduplication keys: [title; author; year]
  Reading 1 file(s)...
    Read malformed_dedup.bib
  Parsing BibTeX entries...
  Warning: Found parsing errors in the BibTeX files:
    - Line 7: Failed to parse entry starting at line 7
    - Line 7: Skipped unparsable content from line 7 to line 11
  Continuing with successfully parsed entries...
  Parsed 2 entries total.
  Deduplicating...
  
  No duplicates found.
  
  Deduplication complete: 2 → 2 entries
  @article{another_good,
    AUTHOR = {Another Author},
    TITLE  = {Another Title},
    YEAR   = {2023}
  }
  
  @article{good_entry,
    AUTHOR = {Good Author},
    TITLE  = {Good Title},
    YEAR   = {2023}
  }

Test error handling with non-existent file
  $ bibdedup non_existent.bib
  Using deduplication keys: [title; author; year]
  Reading 1 file(s)...
  bibdedup: Failed to read file 'non_existent.bib': non_existent.bib: No such file or directory
  [124]

Test error handling with empty input
  $ bibdedup
  bibdedup: No input files specified. Use --help for usage information.
  [124]

Test basic citekey deduplication
  $ cat > duplicates.bib << EOF
  > @article{duplicate_key,
  >   author = {John Doe},
  >   title = {First Version},
  >   year = {2020}
  > }
  > 
  > @article{duplicate_key,
  >   author = {John Doe},
  >   title = {Second Version},
  >   year = {2020},
  >   journal = {Nature}
  > }
  > 
  > @article{unique_key,
  >   author = {Jane Smith},
  >   title = {Different Paper},
  >   year = {2021}
  > }
  > EOF

  $ bibdedup --keys citekey duplicates.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read duplicates.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 3 → 2 entries
  @article{duplicate_key,
    TITLE   = {First Version},
    JOURNAL = {Nature},
    YEAR    = {2020},
    AUTHOR  = {John Doe}
  }
  
  @article{unique_key,
    AUTHOR = {Jane Smith},
    TITLE  = {Different Paper},
    YEAR   = {2021}
  }

Test citekey case sensitivity (case-insensitive matching)
  $ cat > case_test.bib << EOF
  > @article{MyKey,
  >   author = {Author A},
  >   title = {Paper A},
  >   year = {2020}
  > }
  > 
  > @article{mykey,
  >   author = {Author B},
  >   title = {Paper B},
  >   year = {2021}
  > }
  > 
  > @article{MYKEY,
  >   author = {Author C},
  >   title = {Paper C},
  >   year = {2022}
  > }
  > EOF

  $ bibdedup --keys citekey case_test.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read case_test.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 3 → 1 entries
  @article{MyKey,
    TITLE  = {Paper A},
    YEAR   = {2020},
    AUTHOR = {Author A}
  }

Test combining citekey with other fields
  $ cat > combined_keys.bib << EOF
  > @article{paper2020,
  >   author = {John Doe},
  >   title = {Machine Learning},
  >   year = {2020}
  > }
  > 
  > @article{paper2021,
  >   author = {John Doe},
  >   title = {Machine Learning},
  >   year = {2020}
  > }
  > 
  > @article{paper2020,
  >   author = {John Doe},
  >   title = {Deep Learning},
  >   year = {2021}
  > }
  > EOF

Using only citekey - should merge paper2020 entries
  $ bibdedup --keys citekey combined_keys.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read combined_keys.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 3 → 2 entries
  @article{paper2020,
    TITLE  = {Machine Learning},
    YEAR   = {2020},
    AUTHOR = {John Doe}
  }
  
  @article{paper2021,
    AUTHOR = {John Doe},
    TITLE  = {Machine Learning},
    YEAR   = {2020}
  }

Using citekey AND title - should keep all entries since they have different combinations
  $ bibdedup --keys citekey,title combined_keys.bib
  Using deduplication keys: [citekey; title]
  Reading 1 file(s)...
    Read combined_keys.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  No duplicates found.
  
  Deduplication complete: 3 → 3 entries
  @article{paper2020,
    AUTHOR = {John Doe},
    TITLE  = {Machine Learning},
    YEAR   = {2020}
  }
  
  @article{paper2020,
    AUTHOR = {John Doe},
    TITLE  = {Deep Learning},
    YEAR   = {2021}
  }
  
  @article{paper2021,
    AUTHOR = {John Doe},
    TITLE  = {Machine Learning},
    YEAR   = {2020}
  }

Test citekey with whitespace variations
  $ cat > whitespace_test.bib << EOF
  > @article{smith2020,
  >   author = {Jane Smith},
  >   title = {Paper},
  >   year = {2020}
  > }
  > 
  > @article{  smith2020  ,
  >   author = {Jane Smith},
  >   title = {Paper Updated},
  >   year = {2020}
  > }
  > EOF

  $ bibdedup --keys citekey whitespace_test.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read whitespace_test.bib
  Parsing BibTeX entries...
  Parsed 2 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 2 → 1 entries
  @article{smith2020,
    TITLE  = {Paper},
    YEAR   = {2020},
    AUTHOR = {Jane Smith}
  }

Test no duplicates found
  $ cat > no_duplicates.bib << EOF
  > @article{key1,
  >   author = {Author 1},
  >   title = {Paper 1},
  >   year = {2020}
  > }
  > 
  > @article{key2,
  >   author = {Author 2},
  >   title = {Paper 2},
  >   year = {2021}
  > }
  > 
  > @article{key3,
  >   author = {Author 3},
  >   title = {Paper 3},
  >   year = {2022}
  > }
  > EOF

  $ bibdedup --keys citekey no_duplicates.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read no_duplicates.bib
  Parsing BibTeX entries...
  Parsed 3 entries total.
  Deduplicating...
  
  No duplicates found.
  
  Deduplication complete: 3 → 3 entries
  @article{key1,
    AUTHOR = {Author 1},
    TITLE  = {Paper 1},
    YEAR   = {2020}
  }
  
  @article{key2,
    AUTHOR = {Author 2},
    TITLE  = {Paper 2},
    YEAR   = {2021}
  }
  
  @article{key3,
    AUTHOR = {Author 3},
    TITLE  = {Paper 3},
    YEAR   = {2022}
  }

Test field preservation in citekey deduplication
  $ cat > field_preservation.bib << EOF
  > @article{key,
  >   author = {Author},
  >   title = {Title},
  >   year = {2020}
  > }
  > 
  > @article{key,
  >   journal = {Nature},
  >   doi = {10.1234/example}
  > }
  > EOF

  $ bibdedup --keys citekey field_preservation.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read field_preservation.bib
  Parsing BibTeX entries...
  Parsed 2 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 2 → 1 entries
  @article{key,
    DOI     = {10.1234/example},
    TITLE   = {Title},
    JOURNAL = {Nature},
    YEAR    = {2020},
    AUTHOR  = {Author}
  }

Test output to file
  $ cat > output_test.bib << EOF
  > @article{paper2020,
  >   author = {John Doe},
  >   title = {First Version},
  >   year = {2020}
  > }
  > 
  > @article{paper2020,
  >   author = {John Doe},
  >   title = {Updated Version},
  >   year = {2020},
  >   doi = {10.1234/example}
  > }
  > EOF

  $ bibdedup --keys citekey output_test.bib -o deduplicated.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read output_test.bib
  Parsing BibTeX entries...
  Parsed 2 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 2 → 1 entries
  Output written to deduplicated.bib

  $ cat deduplicated.bib
  @article{paper2020,
    DOI    = {10.1234/example},
    TITLE  = {First Version},
    YEAR   = {2020},
    AUTHOR = {John Doe}
  }

Test multiple files with citekey deduplication
  $ cat > file1.bib << EOF
  > @article{shared_key,
  >   author = {Author 1},
  >   title = {Paper from File 1},
  >   year = {2020}
  > }
  > 
  > @article{unique1,
  >   author = {Author A},
  >   title = {Unique Paper 1},
  >   year = {2021}
  > }
  > EOF

  $ cat > file2.bib << EOF
  > @article{shared_key,
  >   author = {Author 1},
  >   title = {Paper from File 2},
  >   year = {2020},
  >   journal = {Nature}
  > }
  > 
  > @article{unique2,
  >   author = {Author B},
  >   title = {Unique Paper 2},
  >   year = {2022}
  > }
  > EOF

  $ bibdedup --keys citekey file1.bib file2.bib
  Using deduplication keys: [citekey]
  Reading 2 file(s)...
    Read file1.bib
    Read file2.bib
  Parsing BibTeX entries...
  Parsed 4 entries total.
  Deduplicating...
  
  Found 1 duplicate groups.
  
  
  Deduplication complete: 4 → 3 entries
  @article{shared_key,
    TITLE   = {Paper from File 1},
    JOURNAL = {Nature},
    YEAR    = {2020},
    AUTHOR  = {Author 1}
  }
  
  @article{unique1,
    AUTHOR = {Author A},
    TITLE  = {Unique Paper 1},
    YEAR   = {2021}
  }
  
  @article{unique2,
    AUTHOR = {Author B},
    TITLE  = {Unique Paper 2},
    YEAR   = {2022}
  }

Test strict mode with citekey deduplication
  $ cat > strict_test.bib << EOF
  > @article{key,
  >   author = {Author},
  >   title = {Title},
  >   author = {Duplicate Author}
  > }
  > EOF

  $ bibdedup --keys citekey --strict strict_test.bib
  Using deduplication keys: [citekey]
  Reading 1 file(s)...
    Read strict_test.bib
  Parsing BibTeX entries...
  Parsed 1 entries total.
  Deduplicating...
  
  No duplicates found.
  
  Deduplication complete: 1 → 1 entries
  bibdedup: Failure("Duplicate fields found in entry: key")
  [124]
