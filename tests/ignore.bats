#!/usr/bin/env bats

export NIX_WATCH_DRY_RUN=true

@test "nix-watch ignores specified directories" {
  nix-watch --ignore ".git" --ignore "node_modules"
  [ "$status" -eq 0 ]
  [[ "${output}" == *".git node_modules"* ]]
}

