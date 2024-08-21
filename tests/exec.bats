#!/usr/bin/env bats

export NIX_WATCH_DRY_RUN=true

@test "nix-watch runs with custom command" {
  run nix-watch --exec "nix build"
  echo "$output" | grep -q "nix build"
  [ $? -eq 0 ]
}

