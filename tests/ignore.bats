#!/usr/bin/env bats

@test "nix-watch ignores specified directories" {
  timeout 2 nix-watch --ignore ".git" --ignore "node_modules"
  [ "$status" -eq 124 ]
  [[ "${output}" == *".git node_modules"* ]]
}

