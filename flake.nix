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
        pkgsMusl = pkgs.pkgsCross.musl64;
        pkgsAarch64 = pkgs.pkgsCross.aarch64-multiplatform-musl;

        bibfmt-native = pkgs.callPackage ./nix/bibfmt.nix {
          nix-filter = nix-filter.lib;
        };
        native = pkgs.callPackage ./nix {
          nix-filter = nix-filter.lib;
          bibfmt = bibfmt-native;
        };
        bibfmt-musl = pkgsMusl.lib.callPackageWith pkgsMusl ./nix/bibfmt.nix {
          static = true;
          nix-filter = nix-filter.lib;
        };
        bibfmt-arm64-musl = (pkgsAarch64.lib.callPackageWith pkgsAarch64 ./nix/bibfmt.nix {
          static = true;
          nix-filter = nix-filter.lib;
          crossName = "aarch64";
        }).overrideAttrs (o: {
          OCAMLFIND_CONF = pkgsAarch64.ocamlPackages.findlib.makeFindlibConf bibfmt-native o;
        });
      in
      {
        packages = {
          inherit native bibfmt-native bibfmt-musl bibfmt-arm64-musl;
          musl = pkgsMusl.lib.callPackageWith pkgsMusl ./nix {
            static = true;
            nix-filter = nix-filter.lib;
            bibfmt = bibfmt-musl;
          };
          arm64-musl = (pkgsAarch64.lib.callPackageWith pkgsAarch64 ./nix {
            static = true;
            nix-filter = nix-filter.lib;
            crossName = "aarch64";
            bibfmt = bibfmt-arm64-musl;
          }).overrideAttrs (o: {
            OCAMLFIND_CONF = pkgsAarch64.ocamlPackages.findlib.makeFindlibConf native o;
          });
        };
      });
}
