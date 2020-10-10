# doi2bib
Small CLI to get a bib entry from a doi or arxiv id

Usage:

    doi2bib 10.1007/s10569-019-9946-9
    doi2bib doi:10.4171/JST/226
    doi2bib arXiv:1609.01724
    doi2bib 1902.00436

It will output the bibtex entry, using the published details when possible.

To run the tests

    opam install --deps-only .
    dune build -p doi2bib
    dune runtest -p doi2bib


### TODO

 - extract journal information from arxiv if doi is not available
 - accept lists of ids
 - use github actions to compile executable binaries and publish the artifacts (see hiw caramel does it!)
 
