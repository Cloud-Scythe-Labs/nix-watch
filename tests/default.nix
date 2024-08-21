{ callPackage
, writeText
, writeShellScriptBin
, nixWatchBin
, bats
, coreutils
, gnused
}:
let
  test_utils = callPackage ./test_utils.nix {
    inherit writeShellScriptBin coreutils gnused;
  };
in
{
  inherit test_utils;
  help = callPackage ./help.nix { inherit bats nixWatchBin writeText; };
  exec = callPackage ./exec.nix { inherit bats nixWatchBin writeText test_utils; };
  ignore = callPackage ./ignore.nix { inherit bats nixWatchBin writeText test_utils; };
  shutdown = callPackage ./shutdown.nix { inherit bats nixWatchBin writeText; };
}

