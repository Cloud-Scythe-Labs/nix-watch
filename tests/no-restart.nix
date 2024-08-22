{ writeTextFile, nixWatchBin, bats }:
let
  name = "no-restart.bats";
in
writeTextFile {
  inherit name;
  text = ''
    #!/usr/bin/env ${bats}/bin/bats

    # TODO: This could be a more in depth check, but for now
    # I've been unable to get the debug message to print. This
    # is because of constraints of using bats to test restarts
    # of a running process. If the initial process finishes
    # before the changes that would trigger `no-restart` are
    # detected, the debug message will not be present once
    # the test finishes.
    @test "nix-watch --no-restart does not restart on changes" {
        run ${nixWatchBin}/bin/nix-watch --debug --no-restart
        [[ "$output" == *"NO_RESTART=true"* ]]
        [ $? -eq 0 ]
    }
  '';
}
