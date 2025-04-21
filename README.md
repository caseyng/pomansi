# pomansi — POor Man’s ANSIble
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

Example
    ./pomansi.sh -u alice \
      -s server1 server2 \
      -c 'whoami' 'uptime' 'df -h' \
      --ssh-opts "-i ~/.ssh/id_rsa -p 2022" \
      --sudo yes \
      --save yes \
      -v
```

## 📝 Requirements
- All remote servers must have the same credentials (same username and authentication method) — because trying to manage different users for each server is a recipe for a headache.
- Key-based authentication is strongly recommended. If the remote servers are not using key-based auth and each server prompts for a password, well… deal with it. Alternatively, it's a great opportunity to set up key-based authentication for a more secure and hassle-free experience.

## 🔒 Sudo Notes
If --sudo yes is passed, the script will:
- Prompt for your password once.
- Test sudo access on the first server.
- Reuse the password across servers using sudo -S.
⚠️ Ensure sudo is installed and allowed for the user on the remote servers.

## 📂 Output Files
When saving is enabled, output for each server will be stored in a uniquely named directory (default: current timestamp), with one file per server.

## 🐚 Why "Poor Man’s Ansible"? AKA Why I Wrote This Script
Sometimes you just want to run a few commands on a bunch of servers. But sometimes… compliance says nope.

I found myself in an environment where:
- Ansible? Nope. Not allowed to use it — not on my machine, and definitely not on the servers.
- Multiple servers? Oh yeah, and they all needed the same commands to run.
- Output? Needed saving and organizing without getting mixed up.
- Some servers needed sudo, some didn't even have it. Go figure.

At first, it seemed harmless — just a few manual SSH sessions. But before I knew it, I was wasting hours copy-pasting commands, consolidating output, and praying I didn’t overwrite anything.

So I wrote this bash script that:
- SSHs into multiple servers
- Runs multiple commands
- Optionally uses sudo (because some days you just need that power)
- Optionally saves outputs with neat filenames (no more accidental overwrites, woohoo!)

No fancy YAML, no agents to manage, just plain old Bash doing what it does best: brute-forcing sanity.

## 💡 Design Considerations
1. I deliberately didn't use getopt because it is not guaranteed to be available on all Linux. 
2. And getopt does not take long options.

## 📜 License
MIT — use freely, modify as you wish.

## 🙏 Contributions
PRs and ideas welcome! Especially for:
- Output formatting
- Parallel execution
- Better sudo handling
