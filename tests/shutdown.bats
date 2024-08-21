#!/usr/bin/env bats

export NIX_WATCH_DRY_RUN=true

@test "nix-watch handles SIGINT gracefully" {
  nix-watch -- sleep 10 &
  sleep 1
  kill -SIGINT $!
  wait $!
  [ "$status" -eq 0 ]
  [[ "${output}" == *"Received SIGINT, shutting down gracefully"* ]]
}

