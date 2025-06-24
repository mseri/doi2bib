# doi2bib ![Build status](https://github.com/mseri/doi2bib/workflows/Main%20workflow/badge.svg)

Small CLI tools to work with bibtex entries: get entries from DOI/arXiv/PubMed IDs and format bibtex files.

<p align="center">
<img src="https://raw.githubusercontent.com/mseri/doi2bib/refs/heads/main/logo.svg"/>
</p>

Just so you know, there is now [Zotero BIB](https://zbib.org/) on the browser that can do this (and more). I will keep maintaining `doi2bib` though, since it is an integral part of my workflow.

## Tools

This package provides two CLI tools:

1. **doi2bib** - Get bibtex entries from DOI, arXiv ID, or PubMed ID (pretty printed with `bibfmt`)
2. **bibfmt** - Pretty print and format bibtex files (using very few dependencies)

## doi2bib Usage

```
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
       With this flag, the tool reads the file and processes its lines
       sequentially, treating them as DOIs, arXiv IDs or PubMed IDs.
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
```

The tool retrieves the bibtex entry using published details when possible.

## bibfmt Usage

```
$ bibfmt --help=plain
NAME
   bibfmt - A little CLI tool to pretty print bibtex files.

SYNOPSIS
   bibfmt [--file=FILE] [--output=OUTPUT] [OPTION]...

OPTIONS
   -f FILE, --file=FILE
       Reads the bib content from the specified file instead of the
       standard input.

   -o OUTPUT, --output=OUTPUT (absent=stdout)
       Saves the pretty printed bib to the specified file.

   --help[=FMT] (default=auto)
       Show this help in format FMT. The value FMT must be one of `auto',
       `pager', `groff' or `plain'. With `auto', the format is `pager` or
       `plain' whenever the TERM env var is `dumb' or undefined.

   --version
       Show version information.

EXIT STATUS
   bibfmt exits with the following status:

   0   on success.

   123 on indiscriminate errors reported on standard error.

   124 on command line parsing errors.

   125 on unexpected internal errors (bugs).

BUGS
   Report bugs to https://github.com/mseri/doi2bib/issues
```

## Examples

### doi2bib Examples

Print bibtex entry to standard output:

```bash
$ doi2bib 10.1007/s10569-019-9946-9
$ doi2bib 1902.00436
$ doi2bib arXiv:1609.01724
$ doi2bib PMC2883744
```

Save bibtex entry to a file:

```bash
$ doi2bib doi:10.4171/JST/226 -o "bibliography.bib"
```

This will create the file if not present or append the bibliography to the existing file.

You can batch-process lists of entries by listing them line by line in a file and using the `--file` option.

### bibfmt Examples

Format a bibtex file and print to stdout:

```bash
$ bibfmt -f bibliography.bib
```

Format a bibtex file and save to a new file:

```bash
$ bibfmt -f messy.bib -o clean.bib
```

Format bibtex content from stdin:

```bash
$ echo "@article{key, title={My Title}, author={John Doe}}" | bibfmt
```

## Installation

Each release comes with attached binaries for Windows, Mac, and Linux. You can simply unpack the binaries (`doi2bib` or `bibfmt`) and place them in a folder accessible by your terminal.

### Building from Source

To build the package yourself, use [opam](https://opam.ocaml.org/):

```bash
$ opam install doi2bib    # or bibfmt if you only need the pretty printer
```

This will install both `doi2bib` and `bibfmt` tools, since the latter is a dependency of `doi2bib`.

To run the tests, clone this repository and from the root of the project run:

```bash
$ opam install --deps-only .    # first time only
$ dune runtest
```

## Troubleshooting

If on macOS you get a `Library not loaded: /usr/local/opt/gmp/lib/libgmp.10.dylib` failure, you will need to install `gmp`:

- MacPorts users: `port install gmp`
- Homebrew users: `brew install gmp`

## Editor Integration

### Zed Configuration

Use the following to configure `bibfmt` as your bibtex formatter in [Zed](https://zed.dev):

```json
"languages": {
  "BibTeX": {
    "formatter": {
      "external": {
        "command": "/path/to/bibfmt"
      }
    }
  }
}
```

Replace `/path/to/bibfmt` with the actual path to your `bibfmt` binary.

### Other Editors

Since `bibfmt` reads from stdin and writes to stdout by default, it can be easily integrated with other editors that support external formatters. The tool will preserve the content if parsing errors are encountered, making it safe to use in automated workflows.

## API References

- [DOI Content Negotiation](https://citation.crosscite.org/docs.html)
- [arXiv API](https://arxiv.org/help/api/index)
- [PubMed API](https://www.ncbi.nlm.nih.gov/home/develop/api/)
