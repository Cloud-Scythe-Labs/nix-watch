{
  description = "Nix Watch watches over your project's source for changes, and runs Nix commands when they occur.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nix-watch = pkgs.callPackage ./nix-watch.nix { };
        tests = pkgs.callPackage ./tests/default.nix {
          inherit (nix-watch) nixWatchBin;
        };
      in
      {
        checks = {
          nix-watch-bats = pkgs.stdenv.mkDerivation {
            name = "nix-watch-bats";
            src = "${nix-watch.nixWatchBin}";
            buildInputs = with pkgs; [ bats gnused ] ++ nix-watch.devTools;
            NIX_WATCH_DRY_RUN = true; # Run nix-watch only once, then exit.

            buildPhase = ''
              runHook preBuild
              ${pkgs.bats}/bin/bats ${tests.help}
              ${pkgs.bats}/bin/bats ${tests.exec}
              ${pkgs.bats}/bin/bats ${tests.ignore}
              ${pkgs.bats}/bin/bats ${tests.shutdown}
              ${pkgs.bats}/bin/bats ${tests.postpone}
              ${pkgs.bats}/bin/bats ${tests.no-restart}
              ${pkgs.bats}/bin/bats ${tests.shell-args}
              ${pkgs.bats}/bin/bats ${tests.workdir}
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p $out
              runHook postInstall
            '';
          };
        };
        inherit nix-watch;
        packages = {
          default = nix-watch.nixWatchBin;
          inherit (nix-watch)
            fswatch
            getopt
            coreutils
            ncurses
            jq
            nixWatchBin
            ;
          inherit (tests)
            help
            exec
            ignore
            shutdown
            postpone
            no-restart
            shell-args
            workdir
            test_utils
            ;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nil
            nixpkgs-fmt
            bats
          ] ++ nix-watch.devTools;
        };
        formatter = pkgs.nixpkgs-fmt;
      });
}
