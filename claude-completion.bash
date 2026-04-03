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

# Extract the name field from YAML frontmatter (between --- markers).
# Returns empty string if no frontmatter or no name field found.
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
# Args: base_dir find_pattern strip_suffix_sed
_claude_discover_commands() {
  local base_dir="$1" find_pattern="$2" strip_suffix="$3"
  find -L "$base_dir" -type f -name "$find_pattern" 2>/dev/null | while read -r file; do
    name=$(_claude_frontmatter_name "$file")
    if [[ -n "$name" ]]; then
      echo "/$name"
    else
      echo "$file" | sed -e "s|^$base_dir/||" -e "$strip_suffix" -e 's|/|:|g' -e 's/^/\//'
    fi
  done
}

_claude_bash_completion()
{
  local cur
  local -a builtin_commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"

  # Built-in slash commands (101 commands as of v2.1.89)
  builtin_commands=(
    /add-dir /advisor /agents /alias /allowed-tools /android /app /autocompact
    /batch /bashes /branch /brief /btw /buddy /bug /checkpoint /chrome
    /claude-api /claude-in-chrome /clear /color /commit /commit-push-pr /compact
    /config /context /continue /copy /cost /debug /desktop /diff /doctor
    /effort /exit /export /extra-usage /fast /feedback /files /fork /help /hooks
    /ide /init /init-verifiers /insights /install /install-github-app
    /install-slack-app /ios /keybindings /login /logout /loop /marketplace /mcp
    /memory /mobile /model /new /passes /permissions /plan /plugin /plugins
    /pr-comments /privacy-settings /quit /rc /release-notes /reload-plugins
    /remote /remote-control /remote-env /rename /reset /resume /review /rewind
    /sandbox /schedule /security-review /settings /simplify /skills /stats
    /status /statusline /stickers /tasks /terminal-setup /theme /think-back
    /ultrareview /update-config /upgrade /usage /vim /voice /web-setup
  )

  # If current word starts with /, complete slash commands
  if [[ "$cur" == /* ]]; then
    local commands_dir="$HOME/.claude/commands"
    local skills_dir="$HOME/.claude/skills"
    local project_root project_commands_dir project_skills_dir
    local custom_commands="" personal_skills="" project_commands="" project_skills=""

    # Detect project root via git
    project_root=$(git rev-parse --show-toplevel 2>/dev/null)

    custom_commands=$(_claude_discover_commands "$commands_dir" "*.md" 's/\.md$//')
    personal_skills=$(_claude_discover_commands "$skills_dir" "SKILL.md" 's|/SKILL\.md$||')

    # Project-level commands and skills (if inside a git repo)
    if [[ -n "$project_root" ]]; then
      project_commands_dir="$project_root/.claude/commands"
      project_skills_dir="$project_root/.claude/skills"

      project_commands=$(_claude_discover_commands "$project_commands_dir" "*.md" 's/\.md$//')
      project_skills=$(_claude_discover_commands "$project_skills_dir" "SKILL.md" 's|/SKILL\.md$||')
    fi

    # Combine all sources and deduplicate
    local all_commands
    all_commands=$(printf '%s\n' "${builtin_commands[@]}" "$custom_commands" "$personal_skills" "$project_commands" "$project_skills" | sort -u)

    mapfile -t COMPREPLY < <(compgen -W "$all_commands" -- "${cur}")
  fi

  return 0
}
complete -F _claude_bash_completion claude
