{ writeShellScriptBin, fswatch, getopt, coreutils, ncurses }:
let
  fswatch' = "${fswatch}/bin/fswatch";
  getopt' = "${getopt}/bin/getopt";
  echo = "${coreutils}/bin/echo";
  pwd = "${coreutils}/bin/pwd";
  stat = "${coreutils}/bin/stat";
  clear = "${ncurses}/bin/clear";

  nixWatchBin = writeShellScriptBin "nix-watch" ''
        # Define some colors that will help distinguish messages
        ANSI_RED='\033[0;31m'
        ANSI_GREEN='\033[32m'
        ANSI_BLUE='\033[0;34m'
        ANSI_RESET='\033[0m'

        usage() {
            ${echo} "USAGE:"
            ${echo} "    $0 [FLAGS] [OPTIONS]"
            ${echo} ""
            ${echo} "FLAGS:"
            ${echo} "    -c, --clear         Clear the screen before each run."
            ${echo} "    -h, --help          Display this message."
            ${echo} "    --ignore-nothing    Ignore nothing [patterns ignored by default: ["result*" ".*\.git"]]."
            ${echo} "    --debug             Show debug output."
            ${echo} "    --no-restart        Don't restart command while it's still running."
            ${echo} "    --postpone          Postpone first run until a file changes"
            ${echo} ""
            ${echo} "OPTIONS:"
            ${echo} "    -x, --exec <cmd>...           Nix command(s) to execute on changes [default: \"flake check\"]."
            ${echo} "    -s, --shell <cmd>...          Shell command(s) to execute on changes."
            ${echo} "    -i, --ignore <pattern>...     Ignore a regex pattern [default: ["result*" ".*\.git"]]"
            ${echo} "    -L, --print-build-logs        Print full build logs on standard error, equal to including the nix '-L' option."
            ${echo} "    -C, --workdir <workdir>       Change working directory before running command [default: current directory]"
            ${echo} ""
            ${echo} "Nix commands (-x) are always executed before shell commands (-s). You can use the \`-- command\` style instead, note you'll need to use full commands, it won't prefix \`nix\` for you.

    By default, the workspace directories of your project and all local dependencies are watched, except for the result/ and .git/ folders."

            exit 1
        }

        debug() {
            if [ "$DEBUG" == true ]; then
                local message="$1"
                ${echo} -e "''${ANSI_GREEN}debug:''${ANSI_RESET} ''${message}"
            fi
        }
        error() {
            local message="$1"
            ${echo} -e "''${ANSI_RED}error:''${ANSI_RESET} ''${message}"
        }

        # Initialize variables with default values
        COMMAND="nix"
        SHELL_ARGS=()
        CLEAR=false
        IGNORE_NOTHING=false
        NO_RESTART=false
        POSTPONE=false
        WATCH_DIR="."
        IGNORE_PATTERNS=("result*" ".*\.git")
        PRINT_BUILD_LOGS=false
        DEBUG=false

        # Parse command-line options using getopt
        options=$(${getopt'} -o x:s:C:i:chL --long clear,help,ignore-nothing,debug,no-restart,postpone,exec:,shell:,workdir:,ignore:,print-build-logs -n "nix-watch" -- "$@")
        if [ $? -ne 0 ]; then
            usage
        fi
        eval set -- "$options"

        # Extract options and their arguments into variables
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -c | --clear)
                    CLEAR=true
                    shift
                    ;;
                --ignore-nothing)
                    IGNORE_NOTHING=true
                    shift
                    ;;
                --debug)
                    DEBUG=true
                    shift
                    ;;
                --no-restart)
                    NO_RESTART=true
                    shift
                    ;;
                --postpone)
                    POSTPONE=true
                    shift
                    ;;
                -x | --exec)
                    shift
                    while [[ "$1" != -* && "$1" != --* && -n "$1" ]]; do
                        COMMAND+=" $1"
                        shift
                    done
                    ;;
                -s | --shell)
                    shift
                    while [[ "$1" != -* && "$1" != --* && -n "$1" ]]; do
                        SHELL_ARGS+=("$1")
                        shift
                    done
                    ;;
                -C | --workdir)
                    WATCH_DIR="$2"
                    shift 2
                    ;;
                -i | --ignore)
                    shift
                    while [[ "$1" != -* && "$1" != --* ]]; do
                        IGNORE_PATTERNS+=("$1")
                        shift
                    done
                    ;;
                -L | --print-build-logs)
                    PRINT_BUILD_LOGS=true
                    shift
                    ;;
                --)
                    shift
                    break
                    ;;
                -h | --help | *)
                    usage
                    ;;
            esac
        done

        # Remaining arguments are considered as shell arguments
        SHELL_ARGS+=("$@")
        shell_args="[''${SHELL_ARGS[@]}]"
        debug "The following arguments will be passed to shell: ''${ANSI_BLUE}$shell_args''${ANSI_RESET}"

        # Construct the final nix command, passing thru the shell args
        if [ "$COMMAND" == "nix" ]; then
            COMMAND+=" flake check"
        fi
        if [ "$PRINT_BUILD_LOGS" == true ]; then
            COMMAND+=" -L"
        fi
        if [[ -n ''${SHELL_ARGS[@]} ]]; then
            COMMAND="$COMMAND && ''${SHELL_ARGS[@]}"
        fi
        debug "Command: ''${ANSI_BLUE}$COMMAND''${ANSI_RESET}"

        # Resolve the watch directory to its absolute path
        WATCH_DIR=$(realpath "$WATCH_DIR")
        debug "Watching directory: ''${ANSI_BLUE}$WATCH_DIR''${ANSI_RESET}"

        if [ "$IGNORE_NOTHING" == true ]; then
            IGNORE_PATTERNS=()
        fi
        ignore_patterns="[''${IGNORE_PATTERNS[@]}]"
        debug "The following patterns will be ignored: ''${ANSI_BLUE}$ignore_patterns''${ANSI_RESET}"
    
        # Ensure the directory exists
        if [ ! -d "$WATCH_DIR" ]; then
            error "Directory '$WATCH_DIR' does not exist."
            exit 1
        fi

        # Temporary file to store the PID of the running command
        PID_FILE="/tmp/$(basename "$0").pid"
        debug "PID filepath: ''${ANSI_BLUE}$PID_FILE''${ANSI_RESET}"

        # Stop the currently running command if any
        stop_running_command() {
            if [ "$CLEAR" == true ]; then
                ${clear}
            fi
            if [ -f "$PID_FILE" ]; then
                previous_pid=$(cat "$PID_FILE")
                debug "Checking status of stale PID $previous_pid"
                if kill -0 "$previous_pid" 2> /dev/null; then
                    debug "Terminating process (PID: $previous_pid)..."
                    kill -TERM "$previous_pid" 2> /dev/null
                    sleep 1 # Allow some time for graceful termination
                    if kill -0 "$previous_pid" 2> /dev/null; then
                        error "Process (PID: $previous_pid) did not terminate. Forcing termination..."
                        kill -KILL "$previous_pid" 2> /dev/null
                        sleep 2 # Allow some time for forceful termination
                    fi
                else
                    debug "Attempted to kill process which is no longer running: (PID $previous_pid)"
                fi
                debug "Removing stale PID $previous_pid"
                rm -f "$PID_FILE"
            fi
        }

        # Keep track of the last modification time
        last_mod_time=0

        run_command() {
            # Get the current modification time of the watched directory
            current_mod_time=$(${stat} -c %Y "$WATCH_DIR")

            debug "Checking modification time for changes"
            debug "Last known mod_time: ''${ANSI_BLUE}$last_mod_time''${ANSI_RESET}"
            debug "Recieved mod_time for comparison: ''${ANSI_BLUE}$current_mod_time''${ANSI_RESET}"
            # Check if the modification time has changed
            if [ "$current_mod_time" -ne "$last_mod_time" ]; then
                debug "Modification time has changed, updating mod_time variable..."
                debug "Setting modification time to: ''${ANSI_BLUE}$current_mod_time''${ANSI_RESET}"
                debug "Previously modified at: ''${ANSI_BLUE}$last_mod_time''${ANSI_RESET}"
                last_mod_time="$current_mod_time"
                debug "mod_time set to: ''${ANSI_BLUE}$last_mod_time''${ANSI_RESET}"

                # Execute the command in the background and capture its PID
                if [ "$NO_RESTART" == true ]; then
                    current_pid=$(cat "$PID_FILE")
                    if [ -f "$PID_FILE" ] && kill -0 "$current_pid" 2>/dev/null; then
                        debug "Attempted to start new process, but PID $current_pid is still running..."
                        return
                    fi
                else
                    stop_running_command
                fi

                cd $WATCH_DIR
                current_dir=$(${pwd})
                debug "Current path is: ''${ANSI_BLUE}$current_dir''${ANSI_RESET}"
                debug "Running command: ''${ANSI_BLUE}$COMMAND''${ANSI_RESET}"
                eval $COMMAND &
                command_pid=$!

                # Save the PID to the PID_FILE
                ${echo} $command_pid > "$PID_FILE"
                ${echo} -e "[''${ANSI_RED}nix-watch''${ANSI_RESET} '$WATCH_DIR']: ''${ANSI_BLUE}$COMMAND''${ANSI_RESET} ''${ANSI_GREEN}(PID: $command_pid)''${ANSI_RESET}"
            else
                debug "Modification time has not changed: ''${ANSI_BLUE}$last_mod_time''${ANSI_RESET}"
                debug "Skipping..."
            fi
        }

        # Construct the fswatch command with ignored directories
        FSWATCH_CMD="${fswatch'} -0"
        for pattern in "''${IGNORE_PATTERNS[@]}"; do
            FSWATCH_CMD+=" -e '$pattern'"
        done
        FSWATCH_CMD+=" $WATCH_DIR"
        debug "fswatch command: ''${ANSI_BLUE}$FSWATCH_CMD''${ANSI_RESET}"

        # Watch the directory for changes on both Linux and macOS
        nix_watch() {
            if [ "$POSTPONE" == false ]; then
                debug "Postpone flag was unset, attempting to run command."
                # Run the command on start, then wait so fswatch doesn't think
                # that changes were made which causing a second run_command to trigger
                run_command & sleep 1
            fi

            eval "$FSWATCH_CMD" | while read -d "" event; do
                debug "Watcher detected changes, found event: ''${ANSI_BLUE}$event''${ANSI_RESET}"
                run_command
            done
        }

        nix_watch
  '';
in
{
  inherit fswatch getopt coreutils ncurses nixWatchBin;
  devTools = [ fswatch getopt coreutils ncurses nixWatchBin ];
}
