#!/usr/bin/env bats

export NIX_WATCH_DRY_RUN=true

@test "nix-watch handles shutdown gracefully" {
  run nix-watch --debug
  [[ "${output}" == *"Received termination signal, cleaning up"* ]]
  [ $? -eq 0 ]
}

