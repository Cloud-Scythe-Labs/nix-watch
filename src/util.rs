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
