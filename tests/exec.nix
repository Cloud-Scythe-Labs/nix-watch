{ writeTextFile, nixWatchBin, bats, test_utils }:
let
  name = "exec.bats";
in
writeTextFile {
  inherit name;
  text = ''
    #!/usr/bin/env ${bats}/bin/bats

    source ${test_utils}/bin/test_utils.sh

    @test "nix-watch --exec runs custom command" {
        run ${nixWatchBin}/bin/nix-watch --exec "nix build"
        clean_output=$(remove_ansi_escape_chars "$output")
        [[ "$clean_output" == *"nix build"* ]]
        [ $? -eq 0 ]
    }

    @test "nix-watch --exec prefixes nix when missing" {
        run ${nixWatchBin}/bin/nix-watch --exec build
        clean_output=$(remove_ansi_escape_chars "$output")
        [[ "$clean_output" == *"nix build"* ]]
        [ $? -eq 0 ]
    }
  '';
}
