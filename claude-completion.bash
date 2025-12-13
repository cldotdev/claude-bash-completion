# ========================================
# Claude Bash Completion
# ========================================

# Wrapper function to merge slash command arguments into a single parameter
claude() {
  # Check if first argument starts with /
  if [[ $# -gt 0 && "$1" == /* ]]; then
    # Merge all arguments into a single quoted string
    command claude "$*"
  else
    # Pass arguments as-is
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
    /memory /model /output-style /permissions /plugin /pr-comments /privacy-settings
    /release-notes /resume /review /rewind /sandbox /security-review /stats /status
    /statusline /terminal-setup /todos /usage /vim
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
