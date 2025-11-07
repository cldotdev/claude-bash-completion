# ========================================
# Claude Bash Completion
# ========================================
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
    /exit /export /help /hooks /init /login /logout /mcp /memory
    /model /output-style /permissions /pr_comments /privacy-settings
    /review /sandbox /rewind /status /statusline /terminal-setup
    /todos /usage /vim
  )

  # If current word starts with /, complete slash commands
  if [[ "$cur" == /* ]]; then
    # Get custom commands from ~/.claude/commands/ directory
    custom_commands=$(find "$commands_dir" -type f -name "*.md" 2>/dev/null | \
                      xargs -n1 basename 2>/dev/null | \
                      sed 's/\.md$//' | \
                      sed 's/^/\//')

    # Combine built-in and custom commands
    opts="${builtin_commands[*]} $custom_commands"

    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
  fi

  return 0
}
complete -F _claude_bash_completion claude
