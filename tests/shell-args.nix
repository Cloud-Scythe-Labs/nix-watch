{ writeTextFile, nixWatchBin, bats, test_utils }:
let
  name = "shell-args.bats";
in
writeTextFile {
  inherit name;
  text = ''
    #!/usr/bin/env ${bats}/bin/bats
  
    source ${test_utils}/bin/test_utils.sh
  
    @test "nix-watch -s appends shell args executed after nix command" {
        run ${nixWatchBin}/bin/nix-watch --debug -s echo "Success"
        echo "$output"
        clean_output=$(remove_ansi_escape_chars "$output")
        [[ "$clean_output" == *"The following arguments will be passed to shell: [echo Success]"* ]]
        [ $? -eq 0 ]
    }
  
    @test "nix-watch -- appends shell args executed after nix command" {
        run ${nixWatchBin}/bin/nix-watch --debug -- echo "Success"
        clean_output=$(remove_ansi_escape_chars "$output")
        [[ "$clean_output" == *"The following arguments will be passed to shell: [echo Success]"* ]]
        [ $? -eq 0 ]
    }
  '';
}
