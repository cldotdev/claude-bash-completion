# Claude Bash Completion

Bash completion script for Claude Code CLI, providing tab completion for both built-in slash commands and custom commands.

## Features

- Auto-completion for all Claude Code built-in slash commands (111 commands as of v2.1.152)
- Auto-completion for CLI flags and their values (64 flags as of v2.1.105)
- Auto-completion for CLI subcommands (11 subcommands as of v2.1.105)
- Auto-completion for custom commands and skills from personal and project directories
- Filesystem fallback when no programmatic completion matches

## Requirements

- Bash shell
- [Claude Code](https://github.com/anthropics/claude-code) installed and configured
- `bash-completion` package (usually pre-installed on most systems)

## Installation

### Method 1: Source in `.bashrc`

1. Clone or download this repository:

```bash
git clone https://github.com/cldotdev/claude-bash-completion.git
```

2. Add the following line to your `~/.bashrc`:

```bash
source /path/to/claude-bash-completion/claude-completion.bash
```

3. Reload your shell configuration:

```bash
source ~/.bashrc
```

### Method 2: Install to system completion directory

Copy the script to your system's bash completion directory:

```bash
sudo cp claude-completion.bash /etc/bash_completion.d/claude
```

Then reload your shell or start a new terminal session.

## Usage

Once installed, you can use tab completion with the `claude` command:

```bash
# Slash commands
claude /         # Shows all available slash commands
claude /con      # Completes to /config, /context, /cost, etc.

# CLI flags
claude --        # Shows all long flags
claude --mo      # Completes to --model

# Flag values
claude --model   # Shows model options: sonnet, opus, haiku, etc.
claude --effort  # Shows effort levels: low, medium, high, max

# Subcommands
claude           # Shows subcommands: doctor, mcp, auth, etc.
claude up        # Completes to update, upgrade

# Custom commands and skills
claude /my-custom-    # If you have custom commands in ~/.claude/commands/
```

## Custom Commands and Skills

The script automatically discovers custom slash commands and skills from these locations:

- Personal commands: `~/.claude/commands/*.md`
- Personal skills: `~/.claude/skills/<name>/SKILL.md`
- Project commands: `<project-root>/.claude/commands/*.md`
- Project skills: `<project-root>/.claude/skills/<name>/SKILL.md`

Subdirectory structures are converted to colon-separated names (e.g., `commands/dev/rails.md` or `skills/dev/rails/SKILL.md` becomes `/dev:rails`).

Project root is detected via `git rev-parse --show-toplevel`. Project-level discovery is skipped when not inside a git repository.

## License

MIT License
