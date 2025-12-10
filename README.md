# doi2bib ![Build status](https://github.com/mseri/doi2bib/workflows/Main%20workflow/badge.svg)

Small CLI tools to work with bibtex entries: get entries from DOI/arXiv/PubMed IDs and format bibtex files.

<p align="center">
<img src="https://raw.githubusercontent.com/mseri/doi2bib/refs/heads/main/logo.svg"/>
</p>

Just so you know, there is now [Zotero BIB](https://zbib.org/) on the browser that can do this (and more). I will keep maintaining `doi2bib` though, since it is an integral part of my workflow.

## Tools

This package provides three CLI tools:

1. **doi2bib** - Get bibtex entries from DOI, arXiv ID, or PubMed ID (pretty printed with `bibfmt`)
2. **bibfmt** - Pretty print and format bibtex files (using very few dependencies)
3. **bibdedup** - Deduplicate BibTeX entries across multiple files

## doi2bib Usage

```
$ doi2bib --help=plain
NAME
   doi2bib - A little CLI tool to get the bibtex entries for DOIs, arXiv
   IDs, or PubMed IDs.

SYNOPSIS
   doi2bib [OPTION]... [FILES]...

DESCRIPTION
   doi2bib reads files containing identifiers (DOIs, arXiv IDs, or
   PubMed IDs) with one identifier per line, and fetches the
   corresponding BibTeX entries.

   The tool automatically infers the type of identifier. You can force
   the CLI to lookup a DOI by using the form 'doi:ID' or an arXiv ID by
   using the form 'arXiv:ID'. PubMed IDs always start with 'PMC'.

   Use '-' as a filename to read identifiers from stdin.

ARGUMENTS
   FILES  Files containing DOIs, arXiv IDs, or PubMed IDs (one per
          line). Use '-' to read from stdin. Multiple files can be
          specified and will be processed sequentially.

OPTIONS
   -o OUTPUT, --output=OUTPUT (absent=stdout)
       Append the bibtex output to the specified file. It will create the
       file if it does not exist. If not specified, writes to stdout.

   --help[=FMT] (default=auto)
       Show this help in format FMT. The value FMT must be one of `auto',
       `pager', `groff' or `plain'. With `auto', the format is `pager` or
       `plain' whenever the TERM env var is `dumb' or undefined.

   --version
       Show version information.

EXAMPLES
   Process a file containing DOIs:
     $ doi2bib dois.txt -o bibliography.bib

   Process multiple files:
     $ doi2bib dois.txt arxiv_ids.txt -o bibliography.bib

   Read from stdin:
     $ echo '10.1145/3357713.3384296' | doi2bib -

   Combine stdin with files:
     $ echo '10.1000/xyz123' | doi2bib - existing.txt -o output.bib

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
   bibfmt [OPTION]... [FILES]...

DESCRIPTION
   bibfmt reads one or more BibTeX files, parses them, and outputs
   formatted BibTeX entries.

   Use '-' as a filename to read from stdin.

ARGUMENTS
   FILES  BibTeX files to format. Use '-' to read from stdin. Multiple
          files can be specified and will be combined.

OPTIONS
   --force
       Force mode: ignore parsing errors and output only successfully
       parsed entries.

   -o OUTPUT, --output=OUTPUT (absent=stdout)
       Saves the pretty printed bib to the specified file. If not
       specified, writes to stdout.

   -q, --quiet
       Quiet mode: suppress all output except errors.

   -s, --strict
       Enable strict parsing mode that rejects BibTeX files with
       duplicate fields.

   --help[=FMT] (default=auto)
       Show this help in format FMT. The value FMT must be one of `auto',
       `pager', `groff' or `plain'. With `auto', the format is `pager` or
       `plain' whenever the TERM env var is `dumb' or undefined.

   --version
       Show version information.

EXAMPLES
   Format a single file:
     $ bibfmt bibliography.bib -o formatted.bib

   Format multiple files:
     $ bibfmt file1.bib file2.bib -o combined.bib

   Read from stdin:
     $ cat input.bib | bibfmt -

   Combine stdin with files:
     $ echo '@article{...}' | bibfmt - existing.bib -o output.bib

   Format with strict mode:
     $ bibfmt --strict bibliography.bib

EXIT STATUS
   bibfmt exits with the following status:

   0   on success.

   123 on indiscriminate errors reported on standard error.

   124 on command line parsing errors.

   125 on unexpected internal errors (bugs).

BUGS
   Report bugs to https://github.com/mseri/doi2bib/issues
```

## bibdedup Usage

```
$ bibdedup --help=plain
NAME
   bibdedup - Deduplicate BibTeX entries across multiple files.

SYNOPSIS
   bibdedup [OPTION]... FILES...

DESCRIPTION
   bibdedup reads one or more BibTeX files, combines all entries, and
   removes duplicates based on specified key fields.

   By default, entries are considered duplicates if they have the same
   title, author, and year (after whitespace normalization and
   case-insensitive comparison).

ARGUMENTS
   FILES  BibTeX files to deduplicate. Use '-' to read from stdin.
          Multiple files can be specified.

OPTIONS
   -i, --interactive
       Enable interactive mode to resolve conflicts. If not set,
       automatically keeps the first occurrence of conflicting fields.

   -k KEYS, --keys=KEYS (absent=title,author,year)
       Comma-separated list of field names to use for duplicate
       detection. Special key 'citekey' matches on citation keys.
       Default: title,author,year

   -o OUTPUT, --output=OUTPUT (absent=stdout)
       Output file for deduplicated BibTeX. If not specified, writes to
       stdout.

   -s, --strict
       Enable strict mode that checks for and reports duplicate fields
       in entries.

   --help[=FMT] (default=auto)
       Show this help in format FMT. The value FMT must be one of `auto',
       `pager', `groff' or `plain'. With `auto', the format is `pager` or
       `plain' whenever the TERM env var is `dumb' or undefined.

   --version
       Show version information.

EXAMPLES
   Deduplicate a single file:
     $ bibdedup bibliography.bib -o clean.bib

   Deduplicate multiple files using DOI:
     $ bibdedup --keys doi file1.bib file2.bib -o merged.bib

   Read from stdin:
     $ cat input.bib | bibdedup -

   Combine stdin with files:
     $ cat extra.bib | bibdedup - existing.bib -o output.bib

   Deduplicate using citekey with interactive conflict resolution:
     $ bibdedup --keys citekey --interactive *.bib -o output.bib

   Deduplicate with strict mode (reports duplicate fields):
     $ bibdedup --strict --keys doi file1.bib file2.bib -o clean.bib

   Deduplicate and output to stdout:
     $ bibdedup --keys title,year file1.bib file2.bib

EXIT STATUS
   bibdedup exits with the following status:

   0   on success.

   124 on command line parsing errors.

   125 on unexpected internal errors (bugs).

BUGS
   Report bugs to https://github.com/mseri/doi2bib/issues
```

## Examples

### doi2bib Examples

Read index entries from standard output and produce bibtex entries (one or more at a time):

```bash
$ doi2bib 10.1007/s10569-019-9946-9
$ doi2bib 1902.00436 arXiv:1609.01724 PMC2883744
```

Save bibtex entry to a file:

```bash
$ doi2bib doi:10.4171/JST/226 -o bibliography.bib
```
This will create the file if not present or append the bibliography to the existing file.

You can batch-process lists of entries by listing them line by line in a file and using the `-i`,`--input` option. For instance,

```bash
$ cat dois.txt
10.1007/s10569-019-9946-9
1902.00436
arXiv:1609.01724
PMC2883744

$ doi2bib -i dois.txt
```

### bibfmt Examples

Format a bibtex file and print to stdout:

```bash
$ bibfmt bibliography.bib
```

Format a bibtex file and save to a new file:

```bash
$ bibfmt messy.bib -o clean.bib
```

Format bibtex content from stdin, using `-` as the filename:

```bash
$ echo "@article{key, title={My Title}, author={John Doe}}" | bibfmt -
```

Format with strict mode to check for duplicate fields (these can be removed
with `bibdedup`):

```bash
$ bibfmt bibliography.bib --strict -q
```

You can use quiet mode to suppress normal output and only see warnings/errors:

```bash
$ bibfmt messy.bib --quiet
```

Force formatting even with parsing errors, by removing all the problematic
entries (_only do this after careful consideration_):

```bash
$ bibfmt problematic.bib --force -o partial.bib
```

### bibdedup Examples

Deduplicate entries from multiple files:

```bash
$ bibdedup file1.bib file2.bib -o merged.bib
```

Use custom keys for duplicate detection:

```bash
$ bibdedup --keys doi papers1.bib papers2.bib -o output.bib
$ bibdedup --keys title,year lib1.bib lib2.bib -o combined.bib
```

Deduplicate using citation keys:

```bash
$ bibdedup --keys citekey old.bib new.bib -o updated.bib
```

Interactive mode for conflict resolution:

```bash
$ bibdedup --interactive --keys title,author,year *.bib -o curated.bib
```

Enable strict mode to check for duplicate fields:

```bash
$ bibdedup --strict --keys doi papers.bib -o clean.bib
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
        "command": "/path/to/bibfmt",
        "arguments": ["-"]
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
