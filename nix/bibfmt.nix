{ stdenv
, lib
, ocamlPackages
, static ? false
, nix-filter
, crossName ? null
}:

with ocamlPackages;

buildDunePackage ({
  pname = "bibfmt";
  version = "n/a";
  src = with nix-filter; filter {
    root = ./..;
    include = [
      "dune-project"
      "bibfmt.opam"
      "bibfmt"
    ];
  };

  propagatedBuildInputs = [
    cmdliner
    re
  ];

} // lib.optionalAttrs (crossName == null) {

  buildPhase = ''
    runHook preBuild
    echo "running ${if static then "static" else "release"} build"
    dune build -p bibfmt -j $NIX_BUILD_CORES --display=short --profile=${if static then "static" else "release"} @install
    runHook postBuild
  '';

} // lib.optionalAttrs (crossName != null) {

  postInstall = ''
    ln -sf $out/bin/bibfmt $out/bin/bibfmt-${crossName}
  '';

})
