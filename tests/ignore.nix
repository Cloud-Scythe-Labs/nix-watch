{ writeText, nixWatchBin, bats, test_utils }:
writeText "ignore.bats" ''
  #!/usr/bin/env ${bats}/bin/bats

  source ${test_utils}/bin/test_utils.sh

  @test "nix-watch --ignore includes specified ignore patterns" {
      run ${nixWatchBin}/bin/nix-watch --debug --ignore ".git" --ignore "node_modules"
      clean_output=$(remove_ansi_escape_chars "$output")
      [[ "$clean_output" == *"The following patterns will be ignored: [.git node_modules result* .*\.git]"* ]]
      [ $? -eq 0 ]
  }

  @test "nix-watch --ignore-nothing removes ignore patterns" {
      run ${nixWatchBin}/bin/nix-watch --debug --ignore-nothing
      clean_output=$(remove_ansi_escape_chars "$output")
      [[ "$clean_output" == *"The following patterns will be ignored: []"* ]]
      [ $? -eq 0 ]
  }
''
