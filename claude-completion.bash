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

  # Built-in slash commands (53 commands)
  builtin_commands=(
    /add-dir /agents /bashes /bug /clear /compact /config /context /copy /cost
    /debug /desktop /doctor /exit /export /extra-usage /fast /fork /help /hooks
    /ide /init /install-github-app /login /logout /mcp /memory /model /output-style
    /permissions /plan /plugin /pr-comments /privacy-settings /release-notes
    /remote-env /rename /resume /review /rewind /sandbox /security-review /stats
    /status /statusline /tasks /teleport /terminal-setup /theme /todos /usage /vim
    /worktree
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
complete -F _claude_bash_completion claude
