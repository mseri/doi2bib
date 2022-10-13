{ stdenv
, lib
, ocamlPackages
, static ? false
, nix-filter
, crossName ? null
}:

with ocamlPackages;

buildDunePackage {
  pname = "doi2bib";
  version = "n/a";
  src = with nix-filter; filter {
    root = ./..;
    include = [
      "dune-project"
      "doi2bib.opam"
      "dune-project"
      "bin"
      "lib"
    ];
  };

  OCAMLFIND_TOOLCHAIN = crossName;
  propagatedBuildInputs = [
    astring
    cohttp-lwt-unix
    cmdliner
    clz
    ezxmlm
    lwt
    bigstringaf
    tls
    re
  ];

  buildPhase = ''
    echo "running\
      ${if static then "static" else "release"} build\
      ${if crossName != null then "for ${crossName}" else ""}"

    dune build bin/doi2bib.exe -j $NIX_BUILD_CORES --display=short --profile=${if static then "static" else "release"}
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv _build/default/bin/doi2bib.exe $out/bin/doi2bib
  '';
}
