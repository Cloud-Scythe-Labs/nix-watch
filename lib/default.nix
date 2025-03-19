# This configuration is not intended to be a nixosModule, but rather
# a build configuration for the nix-watch tool itself.
{ pkgs, lib, ... }: {
  options = {
    nix = {
      name = lib.mkOption {
        type = lib.types.string;
        default = pkgs.nix.name;
        example = pkgs.lix.name;
        description = ''
          The name of the binary nix command line application.
          This is important for finding the nix binary.
        '';
      };
      package = lib.mkOption {
        type = lib.types.derivation;
        default = pkgs.nix;
        example = pkgs.lix;
        description = ''
          The nix command line tool that nix-watch will be built against.
          By default this in latest nix, however, other nix tools may be used instead,
          such as Lix, Determinate Nix, or other nix CLIs.
        '';
      };
    };
  };
  config = {
    nix = {
      name = "nix";
      package = pkgs.nix;
    };
  };
}
