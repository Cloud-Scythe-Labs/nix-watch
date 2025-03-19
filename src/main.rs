use std::{env::current_dir, str::FromStr};

use log::{debug, info, warn};
use notify::{
    event::{AccessKind, AccessMode, DataChange, ModifyKind},
    EventKind, RecursiveMode, Watcher,
};

use crate::{
    cli::{NixWatch, Options, Parser},
    util::{get_nix_commands, get_shell_commands},
};

mod cli;
mod util;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let NixWatch { flags, opts } = NixWatch::parse();

    let Options {
        exec,
        shell,
        workdir,
        print_build_logs: _,
    } = opts;

    env_logger::builder()
        .filter_level(log::LevelFilter::from_str(&flags.log_level)?)
        .init();

    let nix_commands = get_nix_commands(&exec);
    let shell_commands = get_shell_commands(&shell);
    let workdir = workdir.map_or_else(current_dir, Ok)?;

    ctrlc::set_handler(move || {
        std::process::exit(0);
    })?;

    // TODO: add exec portion
    loop {
        let mut watcher =
            notify::recommended_watcher(move |res: notify::Result<notify::Event>| match res {
                Ok(event) => match event.kind {
                    EventKind::Modify(ModifyKind::Metadata(_)) => {
                        debug!("Ignoring metadata change");
                        return;
                    }
                    EventKind::Modify(ModifyKind::Data(DataChange::Any)) => {
                        debug!("Ignoring 'any' data change");
                        return;
                    }
                    EventKind::Access(AccessKind::Close(AccessMode::Write)) => {
                        info!("Close write event: {event:?}");
                    }
                    EventKind::Access(_) => {
                        debug!("Ignoring access event: {event:?}");
                        return;
                    }
                    _ => {
                        info!("Notify event: {event:?}");
                    }
                },
                Err(err) => warn!("Watch error: {err:?}"),
            })?;
        watcher.watch(&workdir.canonicalize()?, RecursiveMode::Recursive)?;
    }
}
