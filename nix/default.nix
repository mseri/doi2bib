{ stdenv
, lib
, ocamlPackages
, static ? false
, nix-filter
, crossName ? null
, bibfmt
}:

with ocamlPackages;

buildDunePackage ({
  pname = "doi2bib";
  version = "n/a";
  src = with nix-filter; filter {
    root = ./..;
    include = [
      "dune-project"
      "doi2bib.opam"
      "doi2bib"
    ];
  };

  propagatedBuildInputs = [
    bibfmt
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

} // lib.optionalAttrs (crossName == null) {

  buildPhase = ''
    runHook preBuild
    echo "running ${if static then "static" else "release"} build"
    dune build doi2bib/bin/doi2bib.exe -j $NIX_BUILD_CORES --display=short --profile=${if static then "static" else "release"}
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    mv _build/default/doi2bib/bin/doi2bib.exe $out/bin/doi2bib
    runHook postInstall
  '';

})
