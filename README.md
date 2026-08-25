# Claude Bash Completion

Bash completion script for the Claude Code CLI, providing tab completion for built-in slash commands, CLI flags and subcommands, and custom commands and skills.

## Features

- Auto-completion for all Claude Code built-in slash commands (125 commands)
- Auto-completion for CLI flags and their values (75 flags)
- Auto-completion for CLI subcommands (24 subcommands), each with its own sub-subcommands, flags, and values, down to `claude plugin marketplace add --scope`
- Auto-completion for built-in tool names on `--tools`, `--allowedTools`, and `--disallowedTools`
- Auto-completion for recorded session IDs on `--resume` and `-r`, most recent first
- Auto-completion for custom commands and skills from personal and project directories
- Slash command completion reaches inside an opening quote, which is where a command that carries arguments has to be typed
- Filesystem fallback when no programmatic completion matches

> Command, flag, and subcommand counts reflect Claude Code v2.1.241. The lists cover what a default account can actually run, including command aliases and entries that `claude --help` hides, such as `claude attach`. Commands that a feature flag leaves switched off are excluded, so completion never offers anything the CLI will refuse.

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
claude '/con     # Completes inside an opening quote as well

# CLI flags
claude --        # Shows all long flags
claude --mo      # Completes to --model

# Flag values
claude --model        # Shows model options: sonnet, opus, haiku, etc.
claude --effort       # Shows effort levels: low, medium, high, xhigh, max
claude --autocompact  # Shows window sizes: auto, 100k, 200k, 500k, 1m
claude --resume       # Shows recorded session IDs, most recent first

# Tool names
claude --tools   # Shows Bash, Read, Edit, Skill, Workflow, etc. plus default

# Subcommands
claude                # Shows subcommands: doctor, mcp, auth, etc.
claude up             # Completes to update, upgrade
claude --verbose mc   # Still completes to mcp, past the leading flags

# Subcommand trees
claude mcp                       # Shows add, add-json, get, list, serve, etc.
claude mcp add --transport       # Shows stdio, sse, http
claude plugin marketplace        # Shows add, list, remove, rm, update
claude auth login --             # Shows --claudeai, --console, --email, --sso
claude rc --spawn                # Shows same-dir, worktree, session

# Custom commands and skills
claude /my-custom-    # If you have custom commands in ~/.claude/commands/
```

### Slash Commands That Carry Arguments

The CLI reads the prompt as a single argument and silently drops any positional argument after it. A slash command and its arguments therefore have to be quoted as a whole:

```bash
claude "/format some text"      # arrives as one prompt
claude /format some text        # only /format arrives; the rest is discarded
```

Completion reaches inside an opening quote, so `claude '/for` plus Tab fills in the command name. Bash closes the quote itself and leaves the cursor past it, so move back inside the quote before typing the arguments.

## How It Works

Loading the script registers the completion function via `complete -o default -F _claude_bash_completion claude`, so pressing Tab after `claude` runs the completion logic. The `-o default` option falls back to filesystem completion when no programmatic match applies. That registration is the whole of it: no alias, no wrapper, nothing shadowing the `claude` command itself.

Completions are drawn from static built-in lists (commands, flags, subcommands, and known flag values), dynamically discovered custom commands and skills (see [Custom Commands and Skills](#custom-commands-and-skills)), the session IDs read from `~/.claude/projects/` (see [Session IDs](#session-ids)), and a filesystem fallback when nothing else matches.

To decide which of those applies, the script first scans the line for the subcommand, skipping the value of any flag that takes one, so `claude --model opus mcp` still resolves to `mcp`. Once a subcommand is found, its own lists take over from the global ones. Where the `bash-completion` package is loaded, the script hands word splitting and path completion to it, so quoted paths and paths containing spaces are handled correctly. Version 2.12 renamed that interface: the script reaches for `_comp_initialize` and `_comp_compgen` first and falls back to `_init_completion` and `_filedir`, which older releases define natively and newer ones leave to a compat file that not every distribution ships. Without the package at all, it reads `COMP_WORDS` and calls `compgen` directly.

## Custom Commands and Skills

The script automatically discovers custom slash commands and skills from these locations:

- Personal commands: `~/.claude/commands/*.md`
- Personal skills: `~/.claude/skills/<name>/SKILL.md`
- Project commands: `<project-root>/.claude/commands/*.md`
- Project skills: `<project-root>/.claude/skills/<name>/SKILL.md`

Subdirectory structures are converted to colon-separated names (e.g., `commands/dev/rails.md` or `skills/dev/rails/SKILL.md` becomes `/dev:rails`).

Project root is detected via `git rev-parse --show-toplevel`. Project-level discovery is skipped when not inside a git repository.

## Session IDs

`--resume` and `-r` complete with the session IDs of the transcripts under `~/.claude/projects/`, ordered by modification time so the most recent session comes first.

Every project directory is read, not just the one for the current working directory, because resuming by ID falls back to scanning all of them: a session started elsewhere is still resumable from here.

## Development

Run the test suite with [bats](https://github.com/bats-core/bats-core), and lint the script with [shellcheck](https://www.shellcheck.net/):

```bash
bats tests/
shellcheck claude-completion.bash
```

The built-in command, flag, and subcommand lists are aligned with each Claude Code release. See [CLAUDE.md](CLAUDE.md) for the alignment procedure.

## License

MIT License
