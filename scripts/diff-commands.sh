#!/usr/bin/env bash
set -euo pipefail

# Compare builtin_commands in claude-completion.bash against commands
# extracted from the installed Claude binary.
# Outputs new and removed commands so you know what to update.
#
# The Claude binary is a Bun-compiled executable with embedded JS.
# Each built-in command is defined as a JS object with fields:
#   type:"local"|"local-jsx"|"prompt", name:"<cmd>", aliases:[...]
#
# When sourced with --source-only, exports extraction functions
# for testing without executing main logic.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETION_FILE="$SCRIPT_DIR/../claude-completion.bash"

# --- Extraction functions ---

# Extract primary command names from type definitions.
# Reads strings output from stdin.
extract_primary_names() {
  local input
  input=$(cat)

  {
    # Pattern 1: type:"local|local-jsx|prompt"...name:"X"
    echo "$input" \
      | grep -oP 'type:"(local|local-jsx|prompt)"[^}]*?name:"([^"]+)"' \
      | grep -oP '(?<=name:")[^"]+'

    # Pattern 2: name:"X"...type:"local|local-jsx|prompt"
    echo "$input" \
      | grep -oP 'name:"([-a-z]+)"[^;]*type:"(local|local-jsx|prompt)"' \
      | grep -oP '(?<=name:")[^"]+'

    # Pattern 3: e3({name:"X",...}) bundled skill registration
    echo "$input" \
      | grep -oP '(?<=e3\(\{name:")[^"]+'

    # Pattern 4: oZ7({name:"X",...}) marketplace-bundled skill registration
    echo "$input" \
      | grep -oP '(?<=oZ7\(\{name:")[^"]+'
  } | sort -u
}

# Extract names that should be excluded (hidden, disabled, internal).
# Reads strings output from stdin.
extract_excluded_names() {
  local input
  input=$(cat)

  {
    # Static isHidden: true or !0
    echo "$input" \
      | grep -oP 'name:"[^"]+"[^}]*isHidden:(!0|true)' \
      | grep -oP '(?<=name:")[^"]+'

    # Static isEnabled: literal false only (not dynamic conditions)
    echo "$input" \
      | grep -oP 'name:"[^"]+"[^}]*isEnabled:\(\)=>(!1|false)([,}]|$)' \
      | grep -oP '(?<=name:")[^"]+'

    # Internal prefix
    echo "mcp__"

    # Internal UI command (not user-invocable)
    echo "rate-limit-options"
  } | sort -u
}

# Extract alias names from command definitions.
# Reads strings output from stdin.
# Handles both "name before aliases" and "aliases before name" patterns.
# Only considers lines with command registration patterns to avoid
# false positives from non-command code (e.g., highlight.js language defs).
extract_aliases() {
  local input
  input=$(cat)

  # Only consider lines with command registration patterns
  local cmd_lines
  cmd_lines=$(echo "$input" \
    | grep -P 'type:"(local|local-jsx|prompt)"|e3\(\{|oZ7\(\{')

  {
    # Pattern 1: name:"X"...aliases:[...]
    echo "$cmd_lines" \
      | grep -oP 'name:"[-a-z]+"[^}]*?aliases:\[[^\]]+\]' \
      | grep -oP '(?<=aliases:\[)[^\]]+' \
      | grep -oP '[a-z][-a-z]*'

    # Pattern 2: aliases:[...]...name:"X"
    echo "$cmd_lines" \
      | grep -oP 'aliases:\[[^\]]+\][^}]*?name:"[-a-z]+"' \
      | grep -oP '(?<=aliases:\[)[^\]]+' \
      | grep -oP '[a-z][-a-z]*'
  } | sort -u
}

# Build final command list: primary names + aliases - exclusions.
# Reads strings output from stdin.
build_command_list() {
  local input
  input=$(cat)

  local primary excluded aliases
  primary=$(echo "$input" | extract_primary_names)
  excluded=$(echo "$input" | extract_excluded_names)
  aliases=$(echo "$input" | extract_aliases)

  {
    echo "$primary"
    echo "$aliases"
  } | sort -u | comm -23 - <(echo "$excluded")
}

# --- Source-only mode for testing ---
if [[ "${1:-}" == "--source-only" ]]; then
  # exit 0 is reachable when executed directly, not when sourced
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

# --- Main ---

claude_bin=$(readlink -f "$(command -v claude)" 2>/dev/null || true)

if [[ -z "$claude_bin" || ! -f "$claude_bin" ]]; then
  echo "Error: Claude binary not found." >&2
  exit 1
fi

claude_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")

# Current commands from completion script
current=$(sed -n '/builtin_commands=(/,/)/p' "$COMPLETION_FILE" \
  | grep -oP '/[a-z][-a-z]*' | sed 's|^/||' | sort -u)
current_count=$(echo "$current" | wc -l)

# Extract from binary
binary_commands=$(strings "$claude_bin" | build_command_list)
binary_count=$(echo "$binary_commands" | wc -l)

echo "Installed: $claude_version"
echo "Script: $current_count commands"
echo "Binary: $binary_count commands"
echo

# Compare
new_commands=$(comm -23 <(echo "$binary_commands") <(echo "$current"))
removed_commands=$(comm -13 <(echo "$binary_commands") <(echo "$current"))

if [[ -n "$new_commands" ]]; then
  echo "New (in binary, not in script):"
  echo "$new_commands" | sed 's/^/  \//'
  echo
fi

if [[ -n "$removed_commands" ]]; then
  echo "Removed (in script, not in binary):"
  echo "$removed_commands" | sed 's/^/  \//'
  echo
fi

if [[ -z "$new_commands" && -z "$removed_commands" ]]; then
  echo "No differences."
fi
