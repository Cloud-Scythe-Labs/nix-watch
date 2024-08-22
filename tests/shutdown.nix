{ writeText, nixWatchBin, bats }:
writeText "shutdown.bats" ''
  #!/usr/bin/env ${bats}/bin/bats

  @test "nix-watch handles shutdown gracefully" {
      run ${nixWatchBin}/bin/nix-watch --debug
      [[ "$output" == *"Received termination signal, cleaning up"* ]]
      [ $? -eq 0 ]
  }
''
