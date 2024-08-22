{ writeTextFile, nixWatchBin, bats }:
let
  name = "shutdown.bats";
in
writeTextFile {
  inherit name;
  text = ''
    #!/usr/bin/env ${bats}/bin/bats
  
    @test "nix-watch handles shutdown gracefully" {
        run ${nixWatchBin}/bin/nix-watch --debug
        [[ "$output" == *"Received termination signal, cleaning up"* ]]
        [ $? -eq 0 ]
    }
  '';
  destination = "/nix-watch-bats/${name}";
}
