#!/usr/bin/env bats

export NIX_WATCH_DRY_RUN=true

@test "nix-watch ignores specified directories" {
  run nix-watch --debug --ignore ".git" --ignore "node_modules"
  [[ "${output}" == *".git node_modules"* ]]
  [ $? -eq 0 ]
}

