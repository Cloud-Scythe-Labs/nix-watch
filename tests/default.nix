{ callPackage
, writeTextFile
, writeShellScriptBin
, runCommand
, nixWatchBin
, bats
, coreutils
, gnused
}:

let
  test_utils = callPackage ./test_utils.nix { inherit writeShellScriptBin coreutils gnused; };
  help = callPackage ./help.nix { inherit bats nixWatchBin writeTextFile; };
  shutdown = callPackage ./shutdown.nix { inherit bats nixWatchBin writeTextFile; };
  postpone = callPackage ./postpone.nix { inherit bats nixWatchBin writeTextFile; };
  no-restart = callPackage ./no-restart.nix { inherit bats nixWatchBin writeTextFile; };
  exec = callPackage ./exec.nix { inherit bats nixWatchBin writeTextFile test_utils; };
  ignore = callPackage ./ignore.nix { inherit bats nixWatchBin writeTextFile test_utils; };
  shell-args = callPackage ./shell-args.nix { inherit bats nixWatchBin writeTextFile test_utils; };
  workdir = callPackage ./shell-args.nix { inherit bats nixWatchBin writeTextFile test_utils; };

  suite = runCommand "mkTestDirectory" { } ''
    mkdir -p $out/nix-watch-bats
    cp -r ${help}       $out/nix-watch-bats/help.bats
    cp -r ${shutdown}   $out/nix-watch-bats/shutdown.bats
    cp -r ${postpone}   $out/nix-watch-bats/postpone.bats
    cp -r ${no-restart} $out/nix-watch-bats/no-restart.bats
    cp -r ${exec}       $out/nix-watch-bats/exec.bats
    cp -r ${ignore}     $out/nix-watch-bats/ignore.bats
    cp -r ${shell-args} $out/nix-watch-bats/shell-args.bats
    cp -r ${workdir}    $out/nix-watch-bats/workdir.bats
  '';
in
{
  inherit
    test_utils
    help
    shutdown
    postpone
    no-restart
    exec
    ignore
    shell-args
    workdir
    suite
    ;
}

