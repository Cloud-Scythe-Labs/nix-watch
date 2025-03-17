use clap::{Args, Parser};

#[derive(Debug, Parser)]
#[command(
    version,
    about = "Nix Watch watches over your project's source for changes, and runs Nix commands when they occur."
)]
struct NixWatch {
    #[command(flatten)]
    flags: Flags,

    #[command(flatten)]
    opts: Options,
}

/// Options that determine the top-level behavior of the watcher
#[derive(Debug, Args)]
struct Flags {
    #[arg(
        long,
        short = 'c',
        env = "NIX_WATCH_CLEAR",
        help = "Clear the screen before each run"
    )]
    clear: bool,

    #[arg(
        long,
        env = "NIX_WATCH_IGNORE_NOTHING",
        help = "Exclude all ignore patterns [default: false]"
    )]
    ignore_nothing: bool,

    #[arg(
        long,
        env = "NIX_WATCH_NO_RESTART",
        help = "Don't restart command while it's still running"
    )]
    no_restart: bool,

    #[arg(
        long,
        env = "NIX_WATCH_POSTPONE",
        help = "Postpone first run until a file changes"
    )]
    postpone: bool,

    #[arg(long, env = "NIX_WATCH_DEBUG", help = "Show nix-watch debug output")]
    debug: bool,
}

/// Optional arguments to supply the watcher
#[derive(Debug, Args)]
struct Options {
    #[arg(
        long,
        short = 'x',
        value_name = "NIX_COMMAND",
        env = "NIX_WATCH_COMMAND",
        help = "Nix command to execute on changes [default: \"nix flake check\"]"
    )]
    exec: Option<String>,

    #[arg(
        long,
        short = 's',
        value_name = "SHELL_COMMAND",
        env = "NIX_WATCH_SHELL_ARGS",
        help = "Shell command(s) to execute on changes"
    )]
    shell: Vec<String>,

    #[arg(
        long,
        short = 'i',
        value_name = "REGEX",
        env = "NIX_WATCH_IGNORE_PATTERNS",
        help = "Ignore a list of regex patterns [default: [\"result*\" \".*\\.git\"]]"
    )]
    ignore: Vec<String>,

    #[arg(
        long,
        short = 'C',
        value_name = "DIR",
        env = "NIX_WATCH_WORKDIR",
        help = "Change working directory before running command [default: current directory]"
    )]
    workdir: Option<String>,

    #[arg(
        long,
        short = 'L',
        env = "NIX_WATCH_PRINT_BUILD_LOGS",
        help = "Print full build logs on standard error, equivalent to including the nix '-L' option"
    )]
    print_build_logs: bool,
}

fn main() {
    let NixWatch { flags, opts } = NixWatch::parse();

    let Options { .. } = opts;

    if flags.debug {
        env_logger::init();
    }
}
