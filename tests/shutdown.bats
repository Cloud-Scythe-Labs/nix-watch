#!/usr/bin/env bats

@test "nix-watch handles SIGINT gracefully" {
  timeout 2 nix-watch -- sleep 10 &
  sleep 1
  kill -SIGINT $!
  wait $!
  [ "$status" -eq 124 ]
  [[ "${output}" == *"Received SIGINT, shutting down gracefully"* ]]
}

