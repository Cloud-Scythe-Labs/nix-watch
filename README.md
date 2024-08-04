# $ nix-watch

Nix Watch watches over your project's source for changes, and runs Nix commands when they occur.

## Features

`nix-watch` is inspired by [`cargo-watch`](https://crates.io/crates/cargo-watch), and can do most things it can do.

```sh
nix-watch --help
USAGE:
    /nix/store/39mkhjs3qga6badlhm2pwhfycw8cqflh-nix-watch/bin/nix-watch [FLAGS] [OPTIONS]

FLAGS:
    -c, --clear         Clear the screen before each run.
    -h, --help          Display this message.
    --ignore-nothing    Ignore nothing [patterns ignored by default: [result* .*.git]].
    --debug             Show debug output.
    --no-restart        Don't restart command while it's still running.
    --postpone          Postpone first run until a file changes

OPTIONS:
    -x, --exec <cmd>              Nix command to execute on changes [default: "flake check"].
    -i, --ignore <pattern>...     Ignore a regex pattern [default: [result* .*.git]]
    -L, --print-build-logs        Print full build logs on standard error, equal to including the nix '-L' option.
    -C, --workdir <workdir>       Change working directory before running command [default: current directory]
```

## Systems

- x86_64-linux
- x86_64-darwin
- aarch64-linux
- aarch64-darwin

## Contributing

Happy to recieve issues, or review PRs.
