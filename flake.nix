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
      in
      {
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
        };
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nil
            nixpkgs-fmt
          ] ++ nix-watch.devTools;
          NIX_WATCH_DEBUG=true;
        };
        formatter = pkgs.nixpkgs-fmt;
      });
}
