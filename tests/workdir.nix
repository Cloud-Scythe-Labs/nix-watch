{ writeText, nixWatchBin, bats, test_utils }:
writeText "workdir.bats" ''
  #!/usr/bin/env ${bats}/bin/bats

  source ${test_utils}/bin/test_utils.sh

  @test "nix-watch --workdir changes the watch directory" {
      run ${nixWatchBin}/bin/nix-watch --debug -C $(pwd)/tests
      echo "$output"
      clean_output=$(remove_ansi_escape_chars "$output")
      [[ "$clean_output" == *"nix-watch/tests"* ]]
      [ $? -eq 0 ]
  }
''
