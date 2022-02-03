# doi2bib ![Build status](https://github.com/mseri/doi2bib/workflows/Main%20workflow/badge.svg)
Small CLI to get a bibtex entry from a DOI, an arXiv ID or a PubMed ID.

Usage:

    $ doi2bib --help=plain
    NAME
       doi2bib - A little CLI tool to get the bibtex entry for a given DOI,
       arXiv or PubMed ID.

    SYNOPSIS
       doi2bib [OPTION]... [ID]

    ARGUMENTS
       ID  A DOI, an arXiv ID or a PubMed ID. The tool tries to automatically
           infer what kind of ID you are using. You can force the cli to
           lookup a DOI by using the form 'doi:ID' or an arXiv ID by using
           the form 'arXiv:ID'. PubMed IDs always start with 'PMC'.

    OPTIONS
       -f FILE, --file=FILE
           With this flag, the tool reads the file and process its lines
           sequentially, treating them as DOIs, arXiv IDs or PubMedIDs.
           Errors will be printed on standard error but will not terminate
           the operation.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of `auto',
           `pager', `groff' or `plain'. With `auto', the format is `pager` or
           `plain' whenever the TERM env var is `dumb' or undefined.

       -o OUTPUT, --output=OUTPUT (absent=stdout)
           Append the bibtex output to the specified file. It will create the
           file if it does not exist.

       --version
           Show version information.

    EXIT STATUS
       doi2bib exits with the following status:

       0   on success.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

    BUGS
       Report bugs to https://github.com/mseri/doi2bib/issues

It will retrieve the bibtex entry, using the published details when possible.

Examples of use (the bibtex entry is printed on standard output):

    $ doi2bib 10.1007/s10569-019-9946-9
    $ doi2bib doi:10.4171/JST/226 -o "bibliography.bib"
    $ doi2bib 1902.00436
    $ doi2bib arXiv:1609.01724
    $ doi2bib PMC2883744

Each release comes with attached binaries for windows, mac and linux.
If you want to build the package yourself, the most immediate way is by running

    $ opam install doi2bib

To run the tests, clone this repository and from of the root of the project run

    $ opam install --deps-only .    # first time only
    $ dune runtest -p doi2bib

API references:

- [DOI content negotiarion](https://citation.crosscite.org/docs.html)
- [arXiv API](https://arxiv.org/help/api/index)
