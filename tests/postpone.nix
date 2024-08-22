{ writeTextFile, nixWatchBin, bats }:
let
  name = "postpone.bats";
in
writeTextFile {
  inherit name;
  text = ''
    #!/usr/bin/env ${bats}/bin/bats

    @test "nix-watch --postpone does not run command on start" {
        run ${nixWatchBin}/bin/nix-watch --debug --postpone
        [[ "$output" == *"Postpone flag was set, exiting without running command."* ]]
        [ $? -eq 0 ]
    }
  '';
  destination = "/nix-watch-bats/${name}";
}
