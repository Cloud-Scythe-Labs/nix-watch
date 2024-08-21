#!/usr/bin/env bats

export NIX_WATCH_DRY_RUN=true

@test "nix-watch runs with custom command" {
  nix-watch --exec "nix build"
  [ "$status" -eq 0 ]
  [[ "${output}" == *"nix build"* ]]
}

