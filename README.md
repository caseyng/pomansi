# Pomansi — POor Man’s ANSIble

`pomansi.sh` is a lightweight Bash utility for running one or more commands across multiple servers over SSH, with optional `sudo`, output saving, and custom SSH options. It’s ideal for quick diagnostics or bulk administrative tasks—no Ansible or Python required.

## 🚀 Features

- Execute multiple commands on multiple servers
- Optional `sudo` support with password prompt
- Save outputs to directory
- Verbose mode for input verification
- Minimal dependencies (just Bash and SSH)

## 🛠️ Usage

```bash
./pomansi.sh [options]
Required
    -u, --user — SSH username
    -s, --servers — List of servers (space-separated)
    -c, --commands — List of commands (quoted if spaced)

Optional
    --output-dir DIR — Output folder name (default: timestamped)
    --save [yes|no] — Save output to files (default: yes)
    --ssh-opts OPTS — Extra SSH options (quoted)
    --sudo [yes|no] — Use sudo (default: no)
    -v, --verbose — Print parsed options
    -h, --help — Show help message

./pomansi.sh -u alice \
  -s server1 server2 \
  -c 'whoami' 'uptime' 'df -h' \
  --ssh-opts "-i ~/.ssh/id_rsa -p 2022" \
  --sudo yes \
  --save yes \
  -v
