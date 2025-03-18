use std::{env::current_dir, str::FromStr};

use crate::{
    cli::{NixWatch, Options, Parser},
    util::{get_nix_commands, get_shell_commands},
};

mod cli;
mod util;

fn main() -> anyhow::Result<()> {
    let NixWatch { flags, opts } = NixWatch::parse();

    let Options {
        exec,
        shell,
        ignore: _,
        workdir,
        print_build_logs: _,
    } = opts;

    env_logger::builder()
        .filter_level(log::LevelFilter::from_str(&flags.log_level)?)
        .init();

    let _nix_commands = get_nix_commands(&exec);
    let _shell_commands = get_shell_commands(&shell);
    let _workdir = workdir.map_or_else(current_dir, Ok)?;

    Ok(())
}
