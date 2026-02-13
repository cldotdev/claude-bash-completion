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
  local found_slash=false

  for arg in "$@"; do
    if [[ "$found_slash" == false && "$arg" == /* ]]; then
      # Found the first slash command
      found_slash=true
      slash_cmd_with_rest="$arg"
    elif [[ "$found_slash" == true ]]; then
      # Everything after slash command gets merged with space separator
      slash_cmd_with_rest="$slash_cmd_with_rest $arg"
    else
      # Before slash command, keep as separate args
      args_before+=("$arg")
    fi
  done

  if [[ "$found_slash" == true ]]; then
    if [[ ${#args_before[@]} -gt 0 ]]; then
      command claude "${args_before[@]}" "$slash_cmd_with_rest"
    else
      command claude "$slash_cmd_with_rest"
    fi
  else
    command claude "$@"
  fi
}

_claude_bash_completion()
{
  local cur
  local -a builtin_commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"

  # --- CLI flag value completions ---
  case "$prev" in
    --model)
      COMPREPLY=( $(compgen -W "sonnet opus haiku claude-sonnet-4-5-20250929 claude-opus-4-6 claude-haiku-4-5-20251001" -- "$cur") )
      return 0
      ;;
    --output-format)
      COMPREPLY=( $(compgen -W "text json stream-json" -- "$cur") )
      return 0
      ;;
    --input-format)
      COMPREPLY=( $(compgen -W "text stream-json" -- "$cur") )
      return 0
      ;;
    --permission-mode)
      COMPREPLY=( $(compgen -W "default acceptEdits plan dontAsk bypassPermissions" -- "$cur") )
      return 0
      ;;
    --fallback-model)
      COMPREPLY=( $(compgen -W "sonnet opus haiku" -- "$cur") )
      return 0
      ;;
    --mcp-config|--system-prompt-file|--settings|--plugin-dir|--add-dir)
      COMPREPLY=( $(compgen -f -- "$cur") )
      return 0
      ;;
  esac

  # --- CLI flags (when word starts with -) ---
  if [[ "$cur" == -* ]]; then
    local flags="
      --add-dir
      --agent
      --agents
      --allowedTools
      --append-system-prompt
      --betas
      --continue
      --dangerously-skip-permissions
      --debug
      --disallowedTools
      --fallback-model
      --fork-session
      --ide
      --include-partial-messages
      --input-format
      --json-schema
      --max-turns
      --mcp-config
      --model
      --output-format
      --permission-mode
      --permission-prompt-tool
      --plugin-dir
      --print
      --resume
      --session-id
      --setting-sources
      --settings
      --strict-mcp-config
      --system-prompt
      --system-prompt-file
      --tools
      --verbose
      --version
      -c
      -p
      -r
      -v
    "
    COMPREPLY=( $(compgen -W "$flags" -- "$cur") )
    return 0
  fi

  # --- Subcommands (first arg, not a flag or slash) ---
  if [[ "$COMP_CWORD" -eq 1 && "$cur" != /* ]]; then
    COMPREPLY=( $(compgen -W "update mcp" -- "$cur") )
    # Don't return — fall through so if nothing matches, no stale completions
    [[ ${#COMPREPLY[@]} -gt 0 ]] && return 0
  fi

  # --- Slash commands (when word starts with /) ---
  # Built-in slash commands (55 commands as of v2.1.63)
  builtin_commands=(
    /add-dir /agents /bashes /batch /bug /clear /compact /config /context /copy /cost
    /debug /desktop /doctor /exit /export /extra-usage /fast /fork /help /hooks
    /ide /init /install-github-app /login /logout /mcp /memory /model /output-style
    /permissions /plan /plugin /pr-comments /privacy-settings /release-notes
    /remote-env /rename /resume /review /rewind /sandbox /security-review /simplify
    /stats /status /statusline /tasks /teleport /terminal-setup /theme /todos /usage
    /vim /worktree
  )

  # If current word starts with /, complete slash commands
  if [[ "$cur" == /* ]]; then
    local commands_dir="$HOME/.claude/commands"
    local skills_dir="$HOME/.claude/skills"
    local project_root project_commands_dir project_skills_dir
    local custom_commands="" personal_skills="" project_commands="" project_skills=""

    # Detect project root via git
    project_root=$(git rev-parse --show-toplevel 2>/dev/null)

    # Personal custom commands: ~/.claude/commands/*.md
    # e.g., ~/.claude/commands/dev/rails.md -> /dev:rails
    custom_commands=$(find -L "$commands_dir" -type f -name "*.md" 2>/dev/null | \
                      sed -e "s|^$commands_dir/||" -e 's/\.md$//' -e 's|/|:|g' -e 's/^/\//')

    # Personal skills: ~/.claude/skills/<name>/SKILL.md
    # e.g., ~/.claude/skills/dev/rails/SKILL.md -> /dev:rails
    personal_skills=$(find -L "$skills_dir" -type f -name "SKILL.md" 2>/dev/null | \
                      sed -e "s|^$skills_dir/||" -e 's|/SKILL\.md$||' -e 's|/|:|g' -e 's/^/\//')

    # Project-level commands and skills (if inside a git repo)
    if [[ -n "$project_root" ]]; then
      project_commands_dir="$project_root/.claude/commands"
      project_skills_dir="$project_root/.claude/skills"

      # Project commands: <root>/.claude/commands/*.md
      project_commands=$(find -L "$project_commands_dir" -type f -name "*.md" 2>/dev/null | \
                         sed -e "s|^$project_commands_dir/||" -e 's/\.md$//' -e 's|/|:|g' -e 's/^/\//')

      # Project skills: <root>/.claude/skills/<name>/SKILL.md
      project_skills=$(find -L "$project_skills_dir" -type f -name "SKILL.md" 2>/dev/null | \
                       sed -e "s|^$project_skills_dir/||" -e 's|/SKILL\.md$||' -e 's|/|:|g' -e 's/^/\//')
    fi

    # Combine all sources and deduplicate
    local all_commands
    all_commands=$(printf '%s\n' "${builtin_commands[@]}" "$custom_commands" "$personal_skills" "$project_commands" "$project_skills" | sort -u)

    mapfile -t COMPREPLY < <(compgen -W "$all_commands" -- "${cur}")
  fi

  return 0
}
complete -o default -F _claude_bash_completion claude
