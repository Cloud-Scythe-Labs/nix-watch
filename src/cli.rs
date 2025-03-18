pub(crate) use clap::Parser;

use clap::{ArgAction, Args, ValueHint};

#[derive(Debug, Parser)]
#[command(
    version,
    about = "Nix Watch watches over your project's source for changes, and runs Nix commands when they occur."
)]
pub(crate) struct NixWatch {
    #[command(flatten)]
    pub(crate) flags: Flags,

    #[command(flatten)]
    pub(crate) opts: Options,
}

/// Options that determine the top-level behavior of the watcher
#[derive(Debug, Args)]
pub(crate) struct Flags {
    #[arg(
        long,
        short = 'c',
        env = "NIX_WATCH_CLEAR",
        help = "Clear the screen before each run"
    )]
    pub(crate) clear: bool,

    #[arg(
        long,
        env = "NIX_WATCH_NO_RESTART",
        help = "Don't restart command while it's still running"
    )]
    pub(crate) no_restart: bool,

    #[arg(
        long,
        env = "NIX_WATCH_POSTPONE",
        help = "Postpone first run until a file changes"
    )]
    pub(crate) postpone: bool,

    #[arg(
        long = "log",
        env = "NIX_WATCH_LOG_LEVEL",
        default_value = "OFF",
        required = false,
        help = "Set nix-watch log output level"
    )]
    pub(crate) log_level: String,
}

/// Optional arguments to supply the watcher
#[derive(Debug, Args)]
pub(crate) struct Options {
    #[arg(
        long,
        short = 'x',
        value_name = "NIX_COMMAND",
        env = "NIX_WATCH_COMMANDS",
        action = ArgAction::Append,
        value_hint = ValueHint::CommandString,
        default_values = vec!["nix flake check"],
        help = "Nix command(s) to execute on changes"
    )]
    pub(crate) exec: Vec<String>,

    #[arg(
        long,
        short = 's',
        value_name = "SHELL_COMMAND",
        env = "NIX_WATCH_SHELL_COMMANDS",
        action = ArgAction::Append,
        value_hint = ValueHint::CommandString,
        help = "Shell command(s) to execute on changes"
    )]
    pub(crate) shell: Vec<String>,

    #[arg(
        long,
        short = 'w',
        value_name = "DIR_PATH",
        value_hint = ValueHint::DirPath,
        help = "The project working directory"
    )]
    pub(crate) workdir: Option<std::path::PathBuf>,

    #[arg(
        long,
        short = 'L',
        env = "NIX_WATCH_PRINT_BUILD_LOGS",
        help = "Print full build logs on standard error, equivalent to including the nix '-L' option"
    )]
    pub(crate) print_build_logs: bool,
}
