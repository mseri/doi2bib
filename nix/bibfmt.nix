{ stdenv
, lib
, ocamlPackages
, static ? false
, nix-filter
, crossName ? null
}:

with ocamlPackages;

buildDunePackage {
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

  buildPhase = ''
    echo "running\
      ${if static then "static" else "release"} build\
      ${if crossName != null then "for ${crossName}" else ""}"

    dune build -p bibfmt -j $NIX_BUILD_CORES --display=short --profile=${if static then "static" else "release"}
  '';

  postInstall = lib.optionalString (crossName != null) ''
    ln -sf $out/bin/bibfmt $out/bin/bibfmt-${crossName}
  '';
}
