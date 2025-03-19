// Bacon has a more robust way of handling commands and even has some decent defaults.
// I like that but I'm also worried that because of the multitude of nix forks and replacement
// CLIs that users may have a hard time with any defaults we add.
// My compromise here is to use macros to expand the requirements from a nix config.
// This would add flexibility when needed, and rigidity by default.
// For instance, a user who would rather use DetSys Nix or Lix can just use `pkgs.<nix flavor>`
// and the program will be rebuilt, statically linking against whichever version is in their
// configuration. The same will go for the default commands, although, for the above examples
// at least, they won't need to change. The option to use aliases will also be available so that
// users don't _need_ to explicitly set the default commands and can still use their preferred
// command names, eg. nix flake check --all-system --keep-going -> nfc-all.

use std::process::Command;

pub const NIX_PREFIX: &str = "nix";

pub fn get_nix_commands(commands: &[String]) -> Vec<Command> {
    commands
        .iter()
        .map(|raw_cmd| {
            let mut raw_cmd: Vec<&str> = raw_cmd.split_whitespace().collect();
            let nix_cmd = raw_cmd
                .first()
                .copied()
                .and_then(|maybe_nix_cmd| {
                    (maybe_nix_cmd.starts_with(NIX_PREFIX)).then_some(raw_cmd.remove(0))
                })
                .unwrap_or(NIX_PREFIX);
            let mut cmd = Command::new(nix_cmd);
            cmd.args(raw_cmd);
            cmd
        })
        .collect()
}

pub fn get_shell_commands(commands: &[String]) -> Vec<Command> {
    commands
        .iter()
        .map(|raw_cmd| {
            let mut raw_cmd: Vec<&str> = raw_cmd.split_whitespace().collect();
            let shell_cmd = raw_cmd.remove(0);
            let mut cmd = Command::new(shell_cmd);
            cmd.args(raw_cmd);
            cmd
        })
        .collect()
}
