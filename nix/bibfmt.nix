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

  OCAMLFIND_TOOLCHAIN = crossName;
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

  buildPhase = ''
    runHook preBuild
    echo "running ${if static then "static" else "release"} build for ${crossName}"
    dune build -p bibfmt -j $NIX_BUILD_CORES --display=short --profile=${if static then "static" else "release"} @install
    ln -sf _build/default/bibfmt.install _build/default/bibfmt-${crossName}.install
    runHook postBuild
  '';

  postInstall = ''
    ln -sf $out/bin/bibfmt $out/bin/bibfmt-${crossName}
  '';

})
