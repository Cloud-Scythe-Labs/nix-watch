#!/usr/bin/env bats

@test "nix-watch runs with custom command" {
  timeout 2 nix-watch --exec "nix build"
  [ "$status" -eq 124 ]
  [[ "${output}" == *"nix build"* ]]
}

