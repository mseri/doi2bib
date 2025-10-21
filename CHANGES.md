# CURRENT

- bibfmt: allow `.` and `/` in the citekey

# 0.7.9 (2025-10-12)

- bibfmt: added --quiet flag to suppress all output except errors.
- bibfmt: added --force flag to ignore parsing errors and output only
  successfully parsed entries.
- bibfmt: refactored deduplication functions - moved all deduplication logic
  (deduplicate_entries, resolve_conflicts, merge_entries_non_interactive) from
  library to bibdedup CLI tool. The library now provides only the core
  find_duplicate_groups function for programmatic use.

# 0.7.8 (2025-10-09)

- bibfmt: introduced new bibdedup CLI tool for deduplicating BibTeX
  entries across multiple files.
- bibfmt: added deduplication library functions (deduplicate_entries,
  find_duplicate_groups, merge_entries_non_interactive) with support
  for configurable keys.
- bibfmt: in strict mode, print a warning if there are multiple
  repeated citekeys (case-insensitive).

# 0.7.7 (2025-08-07)

- bibfmt and doi2bib drop the month field in bibtex. It is
  useless and the way DOI API reports it is also incompatible
  with many bibtex configurations.
- doi2bib: fix for changes in PubMed API
- bibfmt: add support for field entries capitalization and
  stricter parsing. Now, by default, field names are always
  upper cased.
- doi2bib: make the parser fails if there are duplicate fields
  in a bibtex entry.

# 0.7.6 (2025-06-24)

- Introduced new bibfmt tool and library (as a new package)
  for pretty printing and formatting BibTeX files.
- doi2bib: always uses the improved BibTeX pretty-printer
  from bibfmt for output.
- doi2bib: removed custom url-unescaping logic; this is
  now handled by bibfmt in a more systematic way.
- Improved error reporting if parsing a BibTeX entry fails.

# 0.6.2 (2022-10-17)

- Workaround for %-escapes in crossref's doi url field

# 0.6.1 (2022-02-03)

- Fix batch processing: don't quit if some IDs are invalid
- Fix static compilation of artifacts

# 0.6.0 (2022-02-03)

- Support batch processing of files of IDs
- Support append result to file

# 0.5.2 (2021-12-17)

- Move from cuz to the published clz
- Move from dx.doi.org to crossref rest api service,
  the latter gives better and more consistent results and
  does not seem to require a fallback service any longer
- Update arxiv generated bibtex accordingly
- Update ocamlformat

# 0.5.1 (2021-07-01)

- Fix for transitive dependency in cuz
- Improved lower bounds on the opam file

# 0.5.0 (2021-07-01)

- Use cuz for the get calls with compression
- Use arxiv.org/bibtex to obtain the bibtex entry for
  unpublished arxiv manuscripts and rely on the manual
  generation only if that fails reachable.
- Handcrafted pretty printing of the output from crossref

# 0.4.1 (2021-04-20)

- Fix incorrect use of Lwt.ignore_result

# 0.4.0 (2021-04-02)

- Added support for gzipped stream using decompress
