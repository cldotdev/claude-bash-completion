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
  local cur prev opts commands_dir custom_commands
  local -a builtin_commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands_dir="$HOME/.claude/commands"

  # Built-in slash commands
  builtin_commands=(
    /add-dir /agents /bashes /bug /clear /compact /config /context /cost /doctor
    /exit /export /help /hooks /ide /init /install-github-app /login /logout /mcp
    /memory /model /output-style /permissions /plan /plugin /pr-comments /privacy-settings
    /release-notes /remote-env /rename /resume /review /rewind /sandbox /security-review
    /stats /status /statusline /teleport /terminal-setup /theme /todos /usage /vim
  )

  # If current word starts with /, complete slash commands
  if [[ "$cur" == /* ]]; then
    # Get custom commands from ~/.claude/commands/ directory (supports subdirectories)
    # e.g., ~/.claude/commands/dev/rails.md -> /dev:rails
    custom_commands=$(find -L "$commands_dir" -type f -name "*.md" 2>/dev/null | \
                      sed "s|^$commands_dir/||" | \
                      sed 's/\.md$//' | \
                      sed 's|/|:|g' | \
                      sed 's/^/\//')

    # Combine built-in and custom commands
    opts="${builtin_commands[*]} $custom_commands"

    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
  fi

  return 0
}
complete -F _claude_bash_completion claude
