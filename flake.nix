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
        packages.default = nix-watch.nixWatchBin;
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nil
            nixpkgs-fmt
          ] ++ nix-watch.devTools;
        };
        formatter = pkgs.nixpkgs-fmt;
      });
}
