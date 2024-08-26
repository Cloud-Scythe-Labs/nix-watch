# $ nix-watch

Nix Watch watches over your project's source for changes, and runs Nix commands when they occur.


https://github.com/user-attachments/assets/28a6b128-6297-46c6-a47b-d93e86af96b4


## Features

`nix-watch` is inspired by [`cargo-watch`](https://crates.io/crates/cargo-watch), and can do most things it can do.

```sh
USAGE:
    /nix/store/yggqx3ff7q04iy202s6bszw860mbqc21-nix-watch/bin/nix-watch [FLAGS] [OPTIONS]

FLAGS:
    -c, --clear         Clear the screen before each run.
    -h, --help          Display this message.
    --ignore-nothing    Ignore nothing [patterns ignored by default: ["result*" ".*\.git"]].
    --debug             Show debug output.
    --no-restart        Don't restart command while it's still running.
    --postpone          Postpone first run until a file changes

OPTIONS:
    -x, --exec <cmd>             Nix command to execute on changes [default: "nix flake check"].
    -s, --shell <cmd>...         Shell command(s) to execute on changes.
    -i, --ignore <pattern>...    Ignore a regex pattern [default: ["result*" ".*\.git"]]
    -L, --print-build-logs       Print full build logs on standard error, equal to including the nix '-L' option.
    -C, --workdir <workdir>      Change working directory before running command [default: current directory]

Nix commands (-x) are always executed before shell commands (-s). You can use the `-- command` style instead, note you'll need to use full commands, it won't prefix `nix` for you.

By default, the workspace directories of your project and all local dependencies are watched, except for the result/ and .git/ folders.

ENVIRONMENT:
    Environment variables can be delcared through Nix to change the default behavior of `nix-watch`.
    In general, unless specified below, arguments passed via command line override environment variable declarations.
    All environment variables are unset by default. Refer to the above command line flags and options for usage.

FLAGS:
    VARIABLE=TYPE                        POSSIBLE VALUES
    NIX_WATCH_CLEAR=bool,int             `1`, `0`, `true` or `false`, respectively.
    NIX_WATCH_IGNORE_NOTHING=bool,int    `1`, `0`, `true` or `false`, respectively.
    NIX_WATCH_DEBUG=bool,int             `1`, `0`, `true` or `false`, respectively.
    NIX_WATCH_NO_RESTART=bool,int        `1`, `0`, `true` or `false`, respectively.
    NIX_WATCH_POSTPONE=bool,int          `1`, `0`, `true` or `false`, respectively.

OPTIONS:
    VARIABLE=TYPE                          POSSIBLE VALUES
    NIX_WATCH_COMMAND=string               A string representation of a nix command, for example: `"build"`. This is subject to change.
    NIX_WATCH_SHELL_ARGS=string            A string representation of a command, for example: `"nix build && ls"`. This is subject to change.
    NIX_WATCH_IGNORE_PATTERNS=string       A space-separated string representation of regex patterns to ignore, for example `"result* target/"`. This is subject to change.
    NIX_WATCH_PRINT_BUILD_LOGS=bool,int    `1`, `0`, `true` or `false`, respectively.

EXAMPLE DECLARATION:
\`\`\`nix
{
  # ...
  outputs = @inputs{ ... }: {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        # ...
      ] ++ inputs.nix-watch.nix-watch.${system}.devTools;
      NIX_WATCH_CLEAR=true;
      NIX_WATCH_IGNORE_NOTHING=0;
      NIX_WATCH_DEBUG=false;
      NIX_WATCH_NO_RESTART=1;
      NIX_WATCH_POSTPONE="true";

      NIX_WATCH_COMMAND="build";
      NIX_WATCH_SHELL_ARGS="nix fmt --accept-flake-config -- --check .";
      NIX_WATCH_IGNORE_PATTERNS="target/ .*\.gitmodules";
      NIX_WATCH_PRINT_BUILD_LOGS=true;
    };
  };
}
\`\`\`
```

## Systems

- x86_64-linux
- x86_64-darwin
- aarch64-linux
- aarch64-darwin

## Contributing

Happy to recieve issues, or review PRs.
