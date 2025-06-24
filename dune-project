(lang dune 2.8)

(name doi2bib)

(cram enable)

(generate_opam_files true)

(source
 (github mseri/doi2bib))

(license MIT)

(authors "Marcello Seri")

(maintainers "marcello.seri@gmail.com")

(package
 (name doi2bib)
 (synopsis
  "CLI tool to get bibtex entries from DOI/arXiv/PubMed IDs"))

(package
  (name bibfmt)
  (synopsis
  "CLI tool to pretty-print bibtex files")
  (depends
   (ocaml (>= 4.14.0))
   (cmdliner (>= 1.1.0))
   (re (>= 1.0.0))))
