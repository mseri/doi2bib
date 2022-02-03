# 0.6.1 (2022-02-03)

- Fix batch processing: don't quit if some IDs are invalid

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

