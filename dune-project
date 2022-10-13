(lang dune 2.7)

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
  "Small CLI to get a bibtex entry from a DOI, an arXiv ID or a PubMed ID")
 (depends
  (ocaml
   (>= 4.08))
  (astring
   (>= 0.8.0))
  (cohttp-lwt-unix
   (>= 2.5.0))
  (cmdliner
   (>= 1.1.0))
  (clz
   (>= 0.1.0))
  (ezxmlm
   (>= 1.1.0))
  (lwt
   (>= 5.5.0))
  (bigstringaf
   (>= 0.2.0))
  (tls
   (>= 0.12.0))
  (re
   (>= 1.0.0))))
