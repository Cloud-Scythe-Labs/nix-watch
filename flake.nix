{
  description = "Nix Watch watches over your project's source for changes, and runs Nix commands when they occur.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-analyzer-src.follows = "";
    };
    flake-utils.url = "github:numtide/flake-utils";
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
    nix-core = {
      url = "github:Cloud-Scythe-Labs/nix-core";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
  };

  outputs =
    { self
    , nixpkgs
    , crane
    , fenix
    , flake-utils
    , advisory-db
    , nix-core
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      inherit (pkgs) lib;
      pkgs = nixpkgs.legacyPackages.${system};

      rustToolchain = nix-core.toolchains.${system}.mkRustToolchainFromTOML
        ./.rust-toolchain.toml
        "sha256-s1RPtyvDGJaX/BisLT+ifVfuhDT1nZkZ1NcK8sbwELM=";
      craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain.fenix-pkgs;
      src = craneLib.cleanCargoSource ./.;

      commonArgs = {
        inherit src;
        strictDeps = true;
      };

      craneLibLLvmTools = craneLib.overrideToolchain
        (fenix.packages.${system}.complete.withComponents [
          "cargo"
          "llvm-tools"
          "rustc"
        ]);

      cargoArtifacts = craneLib.buildDepsOnly commonArgs;

      nix-watch = craneLib.buildPackage (commonArgs // {
        inherit cargoArtifacts;
        doCheck = false;
      });
    in
    {
      checks = {
        inherit nix-watch;

        clippy = craneLib.cargoClippy (commonArgs // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--all-targets -- --deny warnings";
        });

        doc = craneLib.cargoDoc (commonArgs // {
          inherit cargoArtifacts;
        });

        fmt = craneLib.cargoFmt {
          inherit src;
        };

        toml-fmt = craneLib.taploFmt {
          src = lib.sources.sourceFilesBySuffices src [ ".toml" ];
        };

        audit = craneLib.cargoAudit {
          inherit src advisory-db;
        };

        deny = craneLib.cargoDeny {
          inherit src;
        };

        nextest = craneLib.cargoNextest (commonArgs // {
          inherit cargoArtifacts;
          partitions = 1;
          partitionType = "count";
          cargoNextestPartitionsExtraArgs = "--no-tests=pass";
        });
      };

      packages = {
        default = nix-watch;
      } // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        llvm-coverage = craneLibLLvmTools.cargoLlvmCov (commonArgs // {
          inherit cargoArtifacts;
        });
      };

      apps.default = flake-utils.lib.mkApp {
        drv = nix-watch;
      };

      devShells.default = craneLib.devShell {
        checks = self.checks.${system};
        packages = with pkgs; [
          nil
          nixpkgs-fmt
          bacon
        ];
      };
    });
}
