#!/bin/bash

usage() {
  echo -e "\nUsage: $0 [options]"
  echo -e "\nRequired: "
  echo "  -u, --user                  Remote SSH username"
  echo "  -s, --servers               List of servers (space-separated)"
  echo "  -c, --commands              List of commands (quoted)"
  echo -e "\nOptions:"
  echo "      --concurrency N         Max number of servers to run in parallel (default: 1 for serial, 0 for unlimited concurrency)"
  echo "      --output-dir DIR        Directory for outputs (default: %Y%m%d_%H%M%S)"
  echo "      --save [yes|no]         Whether to save output (default: yes)"
  echo "                              Accepts: yes|y|1|true, no|n|0|false"
  echo "      --ssh-opts              ssh-opts to be passed to the remote server"
  echo "                              Needs to be quoted. e.g. -i <identity file> -p <port>"
  echo "      --sudo [yes|no]         Whether to use sudo (default: no)"
  echo "                              Accepts: yes|y|1|true, no|n|0|false"
  echo "                              No if sudo does not exist on the remote servers"
  echo "  -v, --verbose               Print options to stdout (default: off)"
  echo "  -h, --help                  Show this help and exit"
  echo -e "\nExample:\n  $0 -u alice -s hive.home 192.168.0.1 -c 'whoami' 'uptime' 'df -h' 'ls | wc -l' --ssh-opts '-i ~/.ssh/id_rsa -p 2022' --save yes\n"
  exit 1
}

parse_flag() {
  local __resultvar="$1"
  local maybe_value="$2"
  
  if [ -z "$maybe_value" ] || [[ "$maybe_value" == -* ]]; then
    eval "$__resultvar=yes"
    return 0
  fi

  local value="$(echo "$maybe_value" | tr '[:upper:]' '[:lower:]')"
  case "$value" in
    yes|y|1|true)
      eval "$__resultvar=yes"
      ;;
    no|n|0|false)
      eval "$__resultvar=no"
      ;;
    *)
      echo "Invalid value for --$__resultvar: $value"
      usage
      ;;
  esac
  return 1  # signal: consumed value, needs shift
}

run_ssh() {
  local s="$1"
  echo "=== Connecting $s ==="
  ssh $ssh_opts $user@$s <<EOF | { [[ "$save" == "yes" ]] && tee "$dir/$s" || cat; }
    [[ $sudo == "yes" ]] && echo "$SUDO_PASS" | sudo -S whoami &>/dev/null
    for cmd in ${serialized_commands[@]}; do
      c="\$(echo \$cmd | base64 -d)"
      echo "--- BEGIN \$c ---"
      if [[ $sudo == "yes" ]]; then
        echo "$SUDO_PASS" | sudo -S bash -c "\$c"
      else
        bash -c "\$c"
      fi
      echo "--- END \$c ---"
    done
  echo "=== Disconnecting $s ==="
EOF
}

user=""
servers=()
commands=()
ssh_opts=""
save="yes"
sudo="no"
dir="$(date +%Y%m%d_%H%M%S)"
concurrency=1
verbose="off"
mode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -u|--user)
      shift
      user="$1"
      ;;
    -s|--servers)
      mode="servers"
      ;;
    -c|--commands)
      mode="commands"
      ;;
    --save)
      parse_flag save "$2"
      [[ $? -eq 1 ]] && shift
      ;;
    --ssh-opts)
      shift
      ssh_opts="$1"
      ;;
    --sudo)
      parse_flag sudo "$2"
      [[ $? -eq 1 ]] && shift
      ;;
    --output-dir)
      shift
      dir="$1"
      ;;
    --concurrency)
      shift
      concurrency="$1"
      if ! [[ "$concurrency" =~ ^[0-9]+$ ]]; then
        echo "Invalid value for --concurrency: must be a non-negative number"
        usage
      fi
      ;;
    --verbose)
      verbose="on"
      ;;
    -*)
      echo "Unknown option: $1"
      usage
      ;;
    *)
      case "$mode" in
        servers)
          servers+=("$1")
          ;;
        commands)
          commands+=("$1")
          ;;
        *)
          echo "Unexpected argument: $1"
          usage
          ;;
      esac
      ;;
  esac
  shift
done

# Validate required parameters
[[ -z "$user" ]] && echo "Missing --user" && usage
[[ ${#servers[@]} == 0 ]] && echo "Missing --servers" && usage
[[ ${#commands[@]} == 0 ]] && echo "Missing --commands" && usage

# Check whether -w is supported (GNU base64)
if base64 --help 2>&1 | grep -q -- '-w'; then
  ENCODE() { echo -n "$1" | base64 -w0; }
else
  ENCODE() { echo -n "$1" | base64; }
fi

# Serialize commands for remote SSH commands
serialized_commands=()
for c in "${commands[@]}"; do
  serialized_commands+=($(ENCODE "$c"))
done

# Create output directory if save is true
[[ "$save" == "yes" && ! -d "$dir" ]] && mkdir "$dir"

# Output for verification
if [[ "$verbose" == "on" ]]; then
  echo "User: $user"
  echo "Servers:"
  for s in "${servers[@]}"; do echo "  $s"; done
  echo "Commands:"
  for c in "${commands[@]}"; do echo "  $c"; done
  echo "SSH Opts:"
  echo "  $ssh_opts"
  echo "Save output: $save"
  [[ "$save" == "yes" ]] && echo "Output directory: $dir"
  echo "Sudo: $sudo"
fi

if [[ $sudo == "yes" ]]; then
  for i in {1..3}; do
    read -sp "Enter sudo password: " SUDO_PASS
    echo -n
    result=$(ssh $ssh_opts $user@${servers[0]} "printf '%s\n' '$SUDO_PASS' | sudo -Sk whoami 2>/dev/null")
    [[ $result == 'root' ]] && break || echo "Invalid sudo password. Please try again."
  done
fi

pids=()
for s in "${servers[@]}"; do
  run_ssh "$s" &
  pids+=($!)

  # Wait if we hit the concurrency limit
  while [[ "$concurrency" -gt 0 && ${#pids[@]} -ge "$concurrency" ]]; do
    pid="${pids[0]}"
    [[ -n "$pid" ]] && wait "$pid"
    pids=("${pids[@]:1}")  # remove the finished pid
  done
done

# Wait for any remaining jobs
for pid in "${pids[@]}"; do
  [[ -n "$pid" ]] && wait "$pid"
done
