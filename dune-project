(lang dune 2.7)
(name doi2bib)
(version 85cf81b-dirty)

(cram enable)

(generate_opam_files true)

(source (github mseri/doi2bib))
(license MIT)
(authors "Marcello Seri")
(maintainers "marcello.seri@gmail.com")

(package
 (name doi2bib)
 (synopsis "Small CLI to get a bibtex entry from a DOI, an arXiv ID or a PubMed ID")
 (depends
  (ocaml (>= 4.08))
  (astring (>= 0.8.0))
  (cohttp-lwt-unix (>= 2.5.0))
  (cmdliner (>= 1.0.0))
  (ezxmlm (>= 1.1.0))
  (tls (>= 0.12.0))
 ))
