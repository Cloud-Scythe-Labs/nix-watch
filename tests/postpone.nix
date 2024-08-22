{ writeText, nixWatchBin, bats }:
writeText "postpone.bats" ''
  #!/usr/bin/env ${bats}/bin/bats

  @test "nix-watch --postpone does not run command on start" {
      run ${nixWatchBin}/bin/nix-watch --debug --postpone
      [[ "$output" == *"Postpone flag was set, exiting without running command."* ]]
      [ $? -eq 0 ]
  }
''
