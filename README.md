# Claude Bash Completion

Bash completion script for Claude Code CLI, providing tab completion for both built-in slash commands and custom commands.

## Features

- Auto-completion for all Claude Code built-in slash commands (45 commands)
- Auto-completion for custom commands from `~/.claude/commands/` directory
- Smart detection: completions only trigger when input starts with `/`

## Requirements

- Bash shell
- [Claude Code](https://github.com/anthropics/claude-code) installed and configured
- `bash-completion` package (usually pre-installed on most systems)

## Installation

### Method 1: Source in `.bashrc`

1. Clone or download this repository:

```bash
git clone https://github.com/jlhg/claude-bash-completion.git
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
# Type and press Tab to see all available commands
claude /

# Type partial command and press Tab for completion
claude /con    # Completes to /config, /context, /cost, etc.

# Works with both built-in and custom commands
claude /my-custom-    # If you have custom commands in ~/.claude/commands/
```

## Custom Commands

The script automatically discovers custom commands from `~/.claude/commands/` directory. Any `.md` file in that directory will be available for completion.

## License

MIT License
