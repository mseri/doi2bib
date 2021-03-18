.PHONY: all test benchmark doc repl clean gh-pages

all:
	dune build

test:
	dune runtest

benchmark:
	dune exec benchmark/bench.exe

doc:
	dune build @doc

repl:
	dune utop src

clean:
	dune clean

gh-pages: doc
	git clone `git config --get remote.origin.url` .gh-pages --reference .
	git -C .gh-pages checkout --orphan gh-pages
	git -C .gh-pages reset
	git -C .gh-pages clean -dxf
	cp  -r _build/default/_doc/_html/* .gh-pages
	git -C .gh-pages add .
	git -C .gh-pages config user.email 'docs@project'
	git -C .gh-pages commit -m "Update Pages"
	git -C .gh-pages push origin gh-pages -f
	rm -rf .gh-pages
