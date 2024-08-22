{ writeTextFile, nixWatchBin, bats }:
let
  name = "help.bats";
in
writeTextFile {
  inherit name;
  text = ''
    #!/usr/bin/env ${bats}/bin/bats

    @test "nix-watch --help displays help message" {
        run ${nixWatchBin}/bin/nix-watch --help
        [ "$status" -eq 1 ]
        [ "''${lines[0]}" = "USAGE:" ]
    }
  '';
  destination = "/nix-watch-bats/${name}";
}
