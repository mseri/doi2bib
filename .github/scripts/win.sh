#!/usr/bin/env bash
dir="${1:-_build/default/doi2bib/bin}"
OUTPUT="out"
mkdir "$OUTPUT"
for exe in "$dir/"*.exe ; do
  for dll in $(PATH="/usr/x86_64-w64-mingw32/sys-root/mingw/bin:$PATH" cygcheck "$exe" | grep -F x86_64-w64-mingw32 | sed -e 's/^ *//'); do
    if [ ! -e "$OUTPUT/$(basename "$dll")" ] ; then
      echo "Extracting $dll for $exe"
      cp "$dll" "$OUTPUT/"
    else
      echo "$exe uses $dll (already extracted)"
    fi
  done
  echo "Extracted $exe"
  cp "$exe" "$OUTPUT/"
done
