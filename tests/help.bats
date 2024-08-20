#!/usr/bin/env bats

@test "nix-watch --help displays help message" {
  run nix-watch --help
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "USAGE:" ]
}
