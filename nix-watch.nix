{ writeShellScriptBin, fswatch, getopt, coreutils, ncurses, jq }:
let
  fswatch' = "${fswatch}/bin/fswatch";
  getopt' = "${getopt}/bin/getopt";
  echo = "${coreutils}/bin/echo";
  pwd = "${coreutils}/bin/pwd";
  stat = "${coreutils}/bin/stat";
  clear = "${ncurses}/bin/clear";
  jq' = "${jq}/bin/jq";

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
            ${echo} "    -x, --exec <cmd>              Nix command to execute on changes [default: \"nix flake check\"]."
            ${echo} "    -s, --shell <cmd>...          Shell command(s) to execute on changes."
            ${echo} "    -i, --ignore <pattern>...     Ignore a regex pattern [default: ["result*" ".*\.git"]]"
            ${echo} "    -L, --print-build-logs        Print full build logs on standard error, equal to including the nix '-L' option."
            ${echo} "    -C, --workdir <workdir>       Change working directory before running command [default: current directory]"
            ${echo} ""
            ${echo} "Nix commands (-x) are always executed before shell commands (-s). You can use the \`-- command\` style instead, note you'll need to use full commands, it won't prefix \`nix\` for you.

    By default, the workspace directories of your project and all local dependencies are watched, except for the result/ and .git/ folders."

            exit 1
        }

        # Print a debug message
        debug() {
            if [ "$DEBUG" == true ]; then
                local message="$1"
                ${echo} -e "''${ANSI_GREEN}debug:''${ANSI_RESET} ''${message}"
            fi
        }
        # Print an error message
        error() {
            local message="$1"
            ${echo} -e "''${ANSI_RED}error:''${ANSI_RESET} ''${message}"
        }
        # Remove quotations surrounding a string. This is useful for injecting
        # arguments from nix directly into bash.
        strip_quotes() {
            local input="$1"
            ${echo} "''${input//\"/}"
        }
        # Processes command line arguments that may be white space separated strings
        process_args() {
            local raw_args="$1"
            local processed_args=()
        
            # Loop through each element in the raw_args array
            for cmd_str in "''${raw_args[@]}"; do
                # Check if the string contains spaces
                if [[ "$cmd_str" == *" "* ]]; then
                    # Split the string by spaces and append to the processed_args array
                    IFS=' ' read -r -a split_args <<< "$cmd_str"
                    processed_args+=("''${split_args[@]}")
                else
                    # If no spaces, just append the string
                    processed_args+=("$cmd_str")
                fi
            done
            ${echo} "''${processed_args[@]}"
        }
        # Boolean expressions can be true/false or 1/0, this handles conversion from integer values so that
        # the value captured from the environment will always be true/false.
        convert_int_to_bool() {
            local maybe_int="$1"

            if [[ "$maybe_int" == 0 ]]; then
                ${echo} false
            elif [[ "$maybe_int" == 1 ]]; then
                ${echo} true
            else
                ${echo} "$maybe_int"
            fi
        }

        # Initialize variables with default values
        COMMAND=()
        SHELL_ARGS=()
        CLEAR=false
        IGNORE_NOTHING=false
        NO_RESTART=false
        POSTPONE=false
        WATCH_DIR="."
        IGNORE_PATTERNS=()
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
                        COMMAND+=("$1")
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
        if [[ -z "''${SHELL_ARGS[@]}" ]]; then
            SHELL_ARGS=$(process_args "''${NIX_WATCH_SHELL_ARGS[@]}")
        fi
        shell_args="[''${SHELL_ARGS[@]}]"
        debug "The following arguments will be passed to shell: ''${ANSI_BLUE}$shell_args''${ANSI_RESET}"

        # Construct the final nix command, passing thru the shell args
        DEFAULT_COMMAND=(nix flake check)
        if [[ -z ''${COMMAND[@]} ]]; then
            # If COMMAND is empty, check for env var or use default
            if [[ -n "$NIX_WATCH_COMMAND" ]]; then
                COMMAND=$(process_args "''${NIX_WATCH_COMMAND[@]}")
            else
                COMMAND="''${DEFAULT_COMMAND[@]}"
            fi
        else
            if [[ ! "''${COMMAND[*]}" =~ ^nix ]]; then
                local with_prefix=(nix)
                with_prefix+=("''${COMMAND[@]}")
                COMMAND=("''${with_prefix[@]}")
            fi
            COMMAND=$(process_args "''${COMMAND[@]}")
        fi
        if [ "$PRINT_BUILD_LOGS" == true ]; then
            COMMAND+=("-L")
        fi
        if [[ -n ''${SHELL_ARGS[@]} ]]; then
            COMMAND+=("&&")
            COMMAND+=("''${SHELL_ARGS[@]}")
        fi
        debug "Command: ''${ANSI_BLUE}''${COMMAND[*]}''${ANSI_RESET}"

        # Resolve the watch directory to its absolute path and ensure it exists
        WATCH_DIR=$(realpath "$WATCH_DIR")
        if [ ! -d "$WATCH_DIR" ]; then
            error "Directory '$WATCH_DIR' does not exist."
            exit 1
        fi
        debug "Watching directory: ''${ANSI_BLUE}$WATCH_DIR''${ANSI_RESET}"

        if [[ "$CLEAR" == false && -n "$NIX_WATCH_CLEAR" ]]; then
            CLEAR=$(convert_int_to_bool $NIX_WATCH_CLEAR)
        fi

        DEFAULT_IGNORE_PATTERNS=("result*" ".*\.git")
        if [[ "$IGNORE_NOTHING" == false && -n "$NIX_WATCH_IGNORE_NOTHING" ]]; then
            IGNORE_NOTHING=$(convert_int_to_bool $NIX_WATCH_IGNORE_NOTHING)
        fi
        if [ "$IGNORE_NOTHING" == true ]; then
            IGNORE_PATTERNS=()
        elif [[ -n "$NIX_WATCH_IGNORE_PATTERNS" ]]; then
            IGNORE_PATTERNS+=($(process_args "''${NIX_WATCH_IGNORE_PATTERNS[@]}"))
        else
            IGNORE_PATTERNS+=("''${DEFAULT_IGNORE_PATTERNS[@]}")
        fi
        ignore_patterns="[''${IGNORE_PATTERNS[@]}]"
        debug "The following patterns will be ignored: ''${ANSI_BLUE}$ignore_patterns''${ANSI_RESET}"

        if [[ "$DEBUG" == false && -n "$NIX_WATCH_DEBUG" ]]; then
            DEBUG=$(convert_int_to_bool $NIX_WATCH_DEBUG)
        fi

        if [[ "$NO_RESTART" == false && -n "$NIX_WATCH_NO_RESTART" ]]; then
            NO_RESTART=$(convert_int_to_bool $NIX_WATCH_NO_RESTART)
        fi

        if [[ "$POSTPONE" == false && -n "$NIX_WATCH_POSTPONE" ]]; then
            POSTPONE=$(convert_int_to_bool $NIX_WATCH_POSTPONE)
        fi
        
        # Temporary file to store the PID of the running command
        PID_FILE="/tmp/nix-watch/$(basename "$0").pid"
        debug "PID filepath: ''${ANSI_BLUE}$PID_FILE''${ANSI_RESET}"

        TEMP_LOCK_FILE="/tmp/nix-watch/lock.tmp"
        # Lock file path to store file and directory modification timestamps
        LOCK_FILE="/tmp/nix-watch/$(basename "$0").lock"
        debug "Lock file filepath: ''${ANSI_BLUE}$LOCK_FILE''${ANSI_RESET}"
        # Initialize the lock file
        init_lock_file() {
            debug "Initializing lock file..."
            ${echo} "{ \"$WATCH_DIR\": 0 }" > $LOCK_FILE
        }
        # Get the modification time of a file
        get_mod_time() {
            local file=$1
            ${stat} -c %Y "$file" 2>/dev/null || ${echo} 0
        }
        # Update the lock file with the new modification time
        update_lock_file() {
            local file=$1
            local mod_time=$2

            ${jq'} --arg file "$file" --argjson mod_time "$mod_time" \
               '.[$file] = $mod_time' "$LOCK_FILE" > "$TEMP_LOCK_FILE"
            mv "$TEMP_LOCK_FILE" "$LOCK_FILE"
        }
        # Read the modification time from the lock file
        get_lock_mod_time() {
            local file=$1
            ${jq'} --arg file "$file" '.[$file] // 0' "$LOCK_FILE"
        }

        # Stop the currently running command if any
        stop_running_command() {
            if [ -f "$PID_FILE" ]; then
                previous_pid=$(cat "$PID_FILE")
                debug "Checking status of PID $previous_pid"
                if kill -0 "$previous_pid" 2> /dev/null; then
                    debug "Terminating process (PID: $previous_pid)..."
                    pkill -TERM -P "$previous_pid" 2> /dev/null
                    sleep 1
                    if kill -0 "$previous_pid" 2> /dev/null; then
                        error "Process (PID: $previous_pid) did not terminate. Forcing termination..."
                        pkill -KILL -P "$previous_pid" 2> /dev/null
                    fi
                fi
            fi
            if [ "$CLEAR" == true ]; then
                ${clear}
            fi
        }

        run_command() {
            local event=$1
            current_mod_time=$(get_mod_time "$event")
            last_mod_time=$(get_lock_mod_time "$event")

            if [ "$current_mod_time" -ne "$last_mod_time" ]; then
                debug "Modification time for ''${ANSI_BLUE}$event''${ANSI_RESET} has changed."
                update_lock_file "$event" "$current_mod_time"


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
                debug "Running command: ''${ANSI_BLUE}''${COMMAND[*]}''${ANSI_RESET}"
                eval "''${COMMAND[@]}" &
                command_pid=$!

                # Save the PID to the PID_FILE
                ${echo} $command_pid > "$PID_FILE"
                ${echo} -e "[''${ANSI_RED}nix-watch''${ANSI_RESET} '$WATCH_DIR']: ''${ANSI_BLUE}''${COMMAND[*]}''${ANSI_RESET} ''${ANSI_GREEN}(PID: $command_pid)''${ANSI_RESET}"
            fi
        }

        # Construct the fswatch command with ignored directories
        FSWATCH_CMD="${fswatch'} -1"
        for pattern in "''${IGNORE_PATTERNS[@]}"; do
            FSWATCH_CMD+=" -e '$pattern'"
        done
        FSWATCH_CMD+=" $WATCH_DIR"
        debug "fswatch command: ''${ANSI_BLUE}$FSWATCH_CMD''${ANSI_RESET}"

        # Watch the directory for changes on both Linux and macOS
        nix_watch() {
            eval "$FSWATCH_CMD" | if read -r event; then
                debug "Detected changes in: ''${ANSI_BLUE}$event''${ANSI_RESET}"
                run_command "$event"
            fi
        }

        shutdown() {
            debug "Received termination signal, cleaning up..."
            rm -f $PID_FILE
            if [ "$DEBUG" == false ]; then
                rm -f $LOCK_FILE
            fi
            exit 0
        }

        trap shutdown SIGINT SIGTERM

        mkdir -p /tmp/nix-watch
        init_lock_file
        debug "Initialized lock file: ''${ANSI_BLUE}$(cat $LOCK_FILE)''${ANSI_RESET}"

        if [ "$POSTPONE" == false ]; then
            debug "Postpone flag was unset, attempting to run command."
            # Run the command on start, then wait so fswatch doesn't think
            # that changes were made which causing a second run_command to trigger
            run_command "$WATCH_DIR" & sleep 1
        fi

        while true; do
            nix_watch
        done
  '';
in
{
  inherit fswatch getopt coreutils ncurses jq nixWatchBin;
  devTools = [ fswatch getopt coreutils ncurses jq nixWatchBin ];
}
