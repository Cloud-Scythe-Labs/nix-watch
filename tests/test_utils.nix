{ writeShellScriptBin, coreutils, gnused }:
let
  echo = "${coreutils}/bin/echo";
  sed = "${gnused}/bin/sed";
in
writeShellScriptBin "test_utils.sh" ''
  # Utilities for running nix-watch bats tests.

  remove_ansi_escape_chars() {
      local output="$1"
      ${echo} "$output" | ${sed} -r 's/\x1B\[[0-9;]*[mK]//g'
  }

  export -f remove_ansi_escape_chars
''
