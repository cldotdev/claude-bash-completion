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
    1{
      /^---$/!q
    }
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

# Built-in slash commands (127 commands as of v2.1.219)
_CLAUDE_BUILTIN_COMMANDS=(
  /add-dir /advisor /allowed-tools /android /app
  /artifact-capabilities /artifact-design /artifacts /autocompact /autofix-pr
  /background /bashes /batch /bg /branch /brief /btw /bug
  /cd /checkpoint /checkup /chrome /claude-api /claude-in-chrome /clear /code-review /color
  /compact /config /context /continue /copy /cost
  /dataviz /debug /deep-research /design /design-login /design-sync /desktop /diff /doctor
  /effort /exit /export
  /fast /feedback /fewer-permission-prompts /focus /fork
  /goal
  /help /hooks
  /ide /init /insights /install-github-app /install-slack-app /ios
  /keybindings /keybindings-help
  /login /logout /loop
  /marketplace /mcp /memory /mobile /model /name /new
  /passes /permissions /plan /plugin /plugins /powerup
  /privacy-settings /proactive /quit
  /radio /rc /recap /release-notes /reload-plugins /reload-skills /remote-control
  /remote-env /rename /reset /resume /review /rewind /routines /run /run-skill-generator
  /sandbox /schedule /scroll-speed /security-review /settings /share
  /simplify /skills /stats /status /statusline /stickers /subtask
  /tasks /team-onboarding /teleport /terminal-setup /theme /tp /tui
  /ultraplan /ultrareview /undo /update-config /upgrade /usage /usage-credits
  /verify /voice /web-setup /workflows
)
readonly -a _CLAUDE_BUILTIN_COMMANDS

# CLI flags (72 flags as of v2.1.219)
_CLAUDE_FLAGS=(
  --add-dir
  --agent --agents
  --allow-dangerously-skip-permissions
  --allowedTools --allowed-tools
  --append-system-prompt --append-system-prompt-file
  --ax-screen-reader
  --background --bare --betas --bg --brief
  --chrome
  -c --continue
  --dangerously-skip-permissions
  -d --debug --debug-file
  --disable-slash-commands
  --disallowedTools --disallowed-tools
  --effort
  --exclude-dynamic-system-prompt-sections
  --fallback-model --file --fork-session --forward-subagent-text --from-pr
  -h --help
  --ide
  --include-hook-events --include-partial-messages
  --input-format
  --json-schema
  --max-budget-usd --mcp-config --model
  -n --name --no-chrome --no-session-persistence
  --output-format
  --permission-mode --plugin-dir --plugin-url
  -p --print --prompt-suggestions
  --remote-control --remote-control-session-name-prefix --replay-user-messages
  -r --resume
  --safe-mode
  --session-id --setting-sources --settings --strict-mcp-config
  --system-prompt --system-prompt-file
  --teleport --tmux --tools
  --verbose
  -v --version
  -w --worktree
)
readonly -a _CLAUDE_FLAGS

# CLI subcommands (22 subcommands as of v2.1.219)
_CLAUDE_SUBCOMMANDS=(
  agents attach auth auto-mode daemon doctor gateway install logs
  mcp plugin plugins project rc remote-control respawn rm setup-token
  stop ultrareview update upgrade
)
readonly -a _CLAUDE_SUBCOMMANDS

# Effort levels (shared by --effort flag and /code-review command)
_CLAUDE_EFFORT_LEVELS=(low medium high xhigh max)
readonly -a _CLAUDE_EFFORT_LEVELS

# Flags accepted by the /code-review command (shared by both flag paths)
_CLAUDE_CODE_REVIEW_FLAGS=(--comment --fix)
readonly -a _CLAUDE_CODE_REVIEW_FLAGS

# Positional values accepted by the /code-review command: the effort levels
# plus "ultra", which escalates the review to the cloud-hosted /ultrareview
_CLAUDE_CODE_REVIEW_ARGS=("${_CLAUDE_EFFORT_LEVELS[@]}" ultra)
readonly -a _CLAUDE_CODE_REVIEW_ARGS

# Subcommands accepted by the /plugin command
_CLAUDE_PLUGIN_SUBCOMMANDS=(install uninstall enable disable list marketplace)
readonly -a _CLAUDE_PLUGIN_SUBCOMMANDS

# Sub-subcommands accepted by /plugin marketplace
_CLAUDE_PLUGIN_MARKETPLACE_SUBCOMMANDS=(add remove list update)
readonly -a _CLAUDE_PLUGIN_MARKETPLACE_SUBCOMMANDS

_claude_bash_completion()
{
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Flag and slash command argument value completions
  case "$prev" in
    --model|--fallback-model|/model)
      mapfile -t COMPREPLY < <(compgen -W "default best sonnet opus haiku fable sonnet[1m] opus[1m] fable[1m] opusplan claude-fable-5 claude-fable-5[1m] claude-opus-5 claude-opus-5[1m] claude-sonnet-5 claude-sonnet-5[1m] claude-opus-4-8 claude-opus-4-8[1m] claude-opus-4-7 claude-opus-4-7[1m] claude-opus-4-6 claude-opus-4-6[1m] claude-sonnet-4-6 claude-sonnet-4-6[1m] claude-haiku-4-5 claude-haiku-4-5-20251001" -- "$cur")
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
      mapfile -t COMPREPLY < <(compgen -W "default acceptEdits auto bypassPermissions manual dontAsk plan" -- "$cur")
      return 0
      ;;
    --prompt-suggestions)
      mapfile -t COMPREPLY < <(compgen -W "true false yes no on off 1 0" -- "$cur")
      return 0
      ;;
    --effort)
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_EFFORT_LEVELS[*]}" -- "$cur")
      return 0
      ;;
    /code-review)
      if [[ "$cur" == -* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_CODE_REVIEW_FLAGS[*]}" -- "$cur")
      else
        mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_CODE_REVIEW_ARGS[*]}" -- "$cur")
      fi
      return 0
      ;;
    /plugin)
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_PLUGIN_SUBCOMMANDS[*]}" -- "$cur")
      return 0
      ;;
    marketplace)
      # Only the marketplace sub-subcommand of /plugin; guard against the
      # standalone /marketplace builtin and unrelated contexts.
      if [[ " ${COMP_WORDS[*]} " == *" /plugin "* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_PLUGIN_MARKETPLACE_SUBCOMMANDS[*]}" -- "$cur")
        return 0
      fi
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
    if [[ " ${COMP_WORDS[*]} " == *" /code-review "* ]]; then
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_CODE_REVIEW_FLAGS[*]}" -- "$cur")
    else
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_FLAGS[*]}" -- "$cur")
    fi
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
