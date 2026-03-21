#!/usr/bin/env bash
set -euo pipefail

# Compare builtin_commands in claude-completion.bash against the official docs.
# Outputs new and removed commands so you know what to update.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETION_FILE="$SCRIPT_DIR/../claude-completion.bash"

COMMANDS_URL="https://docs.anthropic.com/en/docs/claude-code/commands"
SKILLS_URL="https://docs.anthropic.com/en/docs/claude-code/skills"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

sed -n '/builtin_commands=(/,/)/p' "$COMPLETION_FILE" \
  | grep -oP '/[a-z][-a-z]*' | sort -u > "$tmpdir/current.txt"

curl -sL "$COMMANDS_URL" \
  | grep -oP '(?<=<code>)/[a-z][-a-z]*(?=[\s<])' \
  | sort -u > "$tmpdir/docs_commands.txt" &

curl -sL "$SKILLS_URL" \
  | sed -n '/<table/,/<\/table>/p' | head -1 \
  | grep -oP '(?<=<code>)/[a-z][-a-z]*(?=[\s<])' \
  | sort -u > "$tmpdir/docs_skills.txt" &

wait
sort -u "$tmpdir/docs_commands.txt" "$tmpdir/docs_skills.txt" > "$tmpdir/docs_all.txt"

current_count="$(wc -l < "$tmpdir/current.txt")"
docs_count="$(wc -l < "$tmpdir/docs_all.txt")"
echo "Current: $current_count commands | Docs: $docs_count commands"
echo

new="$(comm -23 "$tmpdir/docs_all.txt" "$tmpdir/current.txt")"
removed="$(comm -13 "$tmpdir/docs_all.txt" "$tmpdir/current.txt")"

if [[ -n "$new" ]]; then
  echo "New commands (in docs but not in script):"
  echo "$new"
  echo
fi

if [[ -n "$removed" ]]; then
  echo "Removed commands (in script but not in docs):"
  echo "$removed"
  echo
fi

if [[ -z "$new" && -z "$removed" ]]; then
  echo "No differences found. Commands are up to date."
fi
