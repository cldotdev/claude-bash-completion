# ========================================
# Claude Bash Completion
# ========================================

# Wrapper function to merge slash command arguments into a single parameter
# This allows slash commands to receive multi-word arguments properly.
# Example: `claude --model haiku /format 'some text'` becomes
#          `claude --model haiku "/format some text"`
claude() {
  local args_before=()
  local slash_cmd_with_rest=""
  local found_slash=""

  for arg in "$@"; do
    if [[ -z "$found_slash" && "$arg" == /* ]]; then
      found_slash=1
      slash_cmd_with_rest="$arg"
    elif [[ -n "$found_slash" ]]; then
      slash_cmd_with_rest="$slash_cmd_with_rest $arg"
    else
      args_before+=("$arg")
    fi
  done

  if [[ -n "$found_slash" ]]; then
    if [[ ${#args_before[@]} -gt 0 ]]; then
      command claude "${args_before[@]}" "$slash_cmd_with_rest"
    else
      command claude "$slash_cmd_with_rest"
    fi
  else
    command claude "$@"
  fi
}

# Extract the name field from YAML frontmatter (between --- markers).
# Returns an empty string if no frontmatter or no name field found.
_claude_frontmatter_name() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -n '
    1{/^---$/!q}
    2,/^---$/{
      /^name: */{
        s/^name: *//
        s/^["'"'"']//
        s/["'"'"']$//
        p
        q
      }
    }
  ' "$file"
}

# Discover custom commands/skills from a directory.
# Uses frontmatter name if available, falls back to path-based derivation.
# Args: base_dir find_pattern strip_suffix
_claude_discover_commands() {
  local base_dir="$1" find_pattern="$2" strip_suffix="$3"
  find -L "$base_dir" -type f -name "$find_pattern" 2>/dev/null | while read -r file; do
    local name
    name=$(_claude_frontmatter_name "$file")
    if [[ -n "$name" ]]; then
      echo "/$name"
    else
      local rel="${file#"$base_dir"/}"
      rel="${rel%"$strip_suffix"}"
      rel="${rel//\//:}"
      echo "/$rel"
    fi
  done
}

# Built-in slash commands (107 commands as of v2.1.111)
_CLAUDE_BUILTIN_COMMANDS=(
  /add-dir /advisor /agents /allowed-tools /android /app
  /bashes /batch /branch /brief /btw /buddy /bug
  /checkpoint /chrome /claude-api /claude-in-chrome /clear /color
  /compact /config /context /continue /copy /cost
  /debug /desktop /diff /doctor
  /effort /exit /export /extra-usage
  /fast /feedback /focus /fork
  /help /hooks
  /ide /init /insights /install-github-app /install-slack-app /ios
  /keybindings /keybindings-help
  /less-permission-prompts /login /logout /loop /lorem-ipsum
  /marketplace /mcp /memory /mobile /model /new
  /passes /permissions /plan /plugin /plugins /powerup
  /pr-comments /privacy-settings /proactive /quit
  /rc /recap /release-notes /reload-plugins /remember /remote-control
  /remote-env /rename /reset /resume /review /rewind
  /sandbox /schedule /security-review /settings /simplify
  /skillify /skills /stats /status /statusline /stickers /stuck
  /tasks /team-onboarding /terminal-setup /theme /think-back /tui
  /ultraplan /ultrareview /undo /update-config /upgrade /usage
  /verify /voice /web-setup
)
readonly -a _CLAUDE_BUILTIN_COMMANDS

# CLI flags (64 flags as of v2.1.92)
_CLAUDE_FLAGS=(
  --add-dir
  --agent --agents
  --allow-dangerously-skip-permissions
  --allowedTools --allowed-tools
  --append-system-prompt --append-system-prompt-file
  --bare --betas --brief
  --chrome
  -c --continue
  --dangerously-skip-permissions
  -d --debug --debug-file
  --disable-slash-commands
  --disallowedTools --disallowed-tools
  --effort
  --exclude-dynamic-system-prompt-sections
  --fallback-model --file --fork-session --from-pr
  -h --help
  --ide
  --include-hook-events --include-partial-messages
  --input-format
  --json-schema
  --max-budget-usd --mcp-config --mcp-debug --model
  -n --name --no-chrome --no-session-persistence
  --output-format
  --permission-mode --plugin-dir
  -p --print
  --remote-control-session-name-prefix --replay-user-messages
  -r --resume
  --session-id --setting-sources --settings --strict-mcp-config
  --system-prompt --system-prompt-file
  --tmux --tools
  --verbose
  -v --version
  -w --worktree
)
readonly -a _CLAUDE_FLAGS

# CLI subcommands (11 subcommands as of v2.1.92)
_CLAUDE_SUBCOMMANDS=(
  agents auth auto-mode doctor install
  mcp plugin plugins setup-token update upgrade
)
readonly -a _CLAUDE_SUBCOMMANDS

_claude_bash_completion()
{
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Flag value completions
  case "$prev" in
    --model|--fallback-model)
      mapfile -t COMPREPLY < <(compgen -W "default best sonnet opus haiku sonnet[1m] opus[1m] opusplan claude-opus-4-7 claude-opus-4-6 claude-sonnet-4-6 claude-haiku-4-5 claude-haiku-4-5-20251001" -- "$cur")
      return 0
      ;;
    --output-format)
      mapfile -t COMPREPLY < <(compgen -W "text json stream-json" -- "$cur")
      return 0
      ;;
    --input-format)
      mapfile -t COMPREPLY < <(compgen -W "text stream-json" -- "$cur")
      return 0
      ;;
    --permission-mode)
      mapfile -t COMPREPLY < <(compgen -W "default acceptEdits auto bypassPermissions dontAsk plan" -- "$cur")
      return 0
      ;;
    --effort)
      mapfile -t COMPREPLY < <(compgen -W "low medium high xhigh max" -- "$cur")
      return 0
      ;;
    --setting-sources)
      mapfile -t COMPREPLY < <(compgen -W "user project local" -- "$cur")
      return 0
      ;;
    --mcp-config|--system-prompt-file|--append-system-prompt-file|--settings|--debug-file)
      mapfile -t COMPREPLY < <(compgen -f -- "$cur")
      return 0
      ;;
    --plugin-dir|--add-dir)
      mapfile -t COMPREPLY < <(compgen -d -- "$cur")
      return 0
      ;;
  esac

  # Flag completions
  if [[ "$cur" == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_FLAGS[*]}" -- "$cur")
    return 0
  fi

  # Subcommand completions (first argument only)
  if [[ "$COMP_CWORD" -eq 1 && "$cur" != /* && "$cur" != -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_SUBCOMMANDS[*]}" -- "$cur")
    return 0
  fi

  if [[ "$cur" == /* ]]; then
    local commands_dir="$HOME/.claude/commands"
    local skills_dir="$HOME/.claude/skills"
    local project_root project_commands_dir project_skills_dir
    local custom_commands="" personal_skills="" project_commands="" project_skills=""

    # Detect project root via git
    project_root=$(git rev-parse --show-toplevel 2>/dev/null)

    custom_commands=$(_claude_discover_commands "$commands_dir" "*.md" ".md")
    personal_skills=$(_claude_discover_commands "$skills_dir" "SKILL.md" "/SKILL.md")

    # Project-level commands and skills (if inside a git repo)
    if [[ -n "$project_root" ]]; then
      project_commands_dir="$project_root/.claude/commands"
      project_skills_dir="$project_root/.claude/skills"

      project_commands=$(_claude_discover_commands "$project_commands_dir" "*.md" ".md")
      project_skills=$(_claude_discover_commands "$project_skills_dir" "SKILL.md" "/SKILL.md")
    fi

    # Combine all sources and deduplicate
    local all_commands
    all_commands=$(printf '%s\n' "${_CLAUDE_BUILTIN_COMMANDS[@]}" "$custom_commands" "$personal_skills" "$project_commands" "$project_skills" | sort -u)

    mapfile -t COMPREPLY < <(compgen -W "$all_commands" -- "${cur}")
  fi

  return 0
}
complete -o default -F _claude_bash_completion claude
