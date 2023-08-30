{
  description = "doi2bib Nix Flake";

  inputs.nix-filter.url = "github:numtide/nix-filter";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.inputs.flake-utils.follows = "flake-utils";
  inputs.nixpkgs.url = "github:nix-ocaml/nix-overlays";

  outputs = { self, nixpkgs, flake-utils, nix-filter }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}".extend (self: super: {
          ocamlPackages = super.ocaml-ng.ocamlPackages_4_14;
        });
        native = pkgs.callPackage ./nix {
          nix-filter = nix-filter.lib;
        };

      in
      {
        packages = {
          inherit native;
          musl =
            let
              pkgs' = pkgs.pkgsCross.musl64;
            in
            pkgs'.lib.callPackageWith pkgs' ./nix {
              static = true;
              nix-filter = nix-filter.lib;
            };
          arm64-musl =
            let
              pkgs' = pkgs.pkgsCross.aarch64-multiplatform-musl;
            in
            (pkgs'.lib.callPackageWith pkgs' ./nix {
              static = true;
              nix-filter = nix-filter.lib;
              crossName = "aarch64";
            }).overrideAttrs (o: {
              OCAMLFIND_CONF = pkgs'.ocamlPackages.findlib.makeFindlibConf native o;
            });
        };
      });
}
