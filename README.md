# doi2bib ![Build status](https://github.com/mseri/doi2bib/workflows/Main%20workflow/badge.svg)
Small CLI to get a bibtex entry from a DOI or an arXiv ID.

Usage:

    $ doi2bib --help
    SYNOPSIS

        doi2bib <ID>

    DESCRIPTION

        A little CLI tool to get the bibtex entry for a given DOI or arXivID.

    OPTIONS

        ID
            A DOI or an arXiv ID. The tool tries to automatically infer what kind of
            ID you are using. You can force the cli to lookup a DOI by using the
            form 'doi:ID' or an arXiv ID by using the form 'arXiv:ID'.

It will output the bibtex entry, using the published details when possible.

Examples of use (the bibtex entry is printed on standard output):

    $ doi2bib 10.1007/s10569-019-9946-9
    $ doi2bib doi:10.4171/JST/226
    $ doi2bib arXiv:1609.01724
    $ doi2bib 1902.00436

Each release comes with attached binaries for windows, mac and linux.
If you want to build the package yourself, the most immediate way is by running

    $ opam pin add doi2bib https://github.com/mseri/doi2bib.git
    $ opam install doi2bib

To run the tests, clone this repository and from of the root of the project run

    $ opam install --deps-only .    # first time only
    $ dune runtest -p doi2bib

API references:

- [DOI content negotiarion](https://citation.crosscite.org/docs.html)
- [arXiv API](https://arxiv.org/help/api/index)
