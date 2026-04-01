#!/usr/bin/env bash
set -euo pipefail

# Compare builtin_commands in claude-completion.bash against the official docs
# and the installed Claude binary.
# Outputs new and removed commands so you know what to update.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETION_FILE="$SCRIPT_DIR/../claude-completion.bash"

COMMANDS_URL="https://docs.anthropic.com/en/docs/claude-code/commands"
SKILLS_URL="https://docs.anthropic.com/en/docs/claude-code/skills"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# --- Current commands from completion script ---
sed -n '/builtin_commands=(/,/)/p' "$COMPLETION_FILE" \
  | grep -oP '/[a-z][-a-z]*' | sort -u > "$tmpdir/current.txt"

current_count="$(wc -l < "$tmpdir/current.txt")"

# --- Installed version ---
claude_version=$(claude --version 2>/dev/null | head -1 || echo "unknown")
echo "Installed: $claude_version"
echo "Script: $current_count commands"
echo

# --- Resolve binary path early so we can start scanning in parallel ---
claude_bin=$(readlink -f "$(command -v claude)" 2>/dev/null || true)

# --- Fetch docs and scan binary in parallel ---
curl -sL "$COMMANDS_URL" \
  | grep -oP '(?<=<code>)/[a-z][-a-z]*(?=[\s<])' \
  | sort -u > "$tmpdir/docs_commands.txt" &

curl -sL "$SKILLS_URL" \
  | sed -n '/<table/,/<\/table>/p' | head -1 \
  | grep -oP '(?<=<code>)/[a-z][-a-z]*(?=[\s<])' \
  | sort -u > "$tmpdir/docs_skills.txt" &

if [[ -n "$claude_bin" && -f "$claude_bin" ]]; then
  # Filesystem paths
  binary_exclude='/(bin|dev|emcc|etc|fish|lib|mnt|npx|opt|proc|sbin|sh|tmp|usr|var|zsh'
  # Dynamic linker
  binary_exclude+='|ld-linux-|ld-musl-'
  # Shell / tool names
  binary_exclude+='|bash|wrapper|worker'
  # AWS Bedrock / Azure API paths
  binary_exclude+='|all|allcompartments|async-invoke|authorize|automated-reasoning-policies'
  binary_exclude+='|callback|change|claims|create|create-foundation-model-agreement'
  binary_exclude+='|custom-models|dashboard|delete-foundation-model-agreement|devicecode'
  binary_exclude+='|displaydns|evaluation-jobs|events|foundation-models|groups|guardrails'
  binary_exclude+='|imported-models|inference-profiles|issue|logonid|metrics|model-copy-jobs'
  binary_exclude+='|model-customization-jobs|model-import-jobs|model-invocation-job'
  binary_exclude+='|model-invocation-jobs|prompt-routers|properties'
  binary_exclude+='|provisioned-model-throughput|provisioned-model-throughputs'
  binary_exclude+='|rate-limit-options|register|transfer|use-case-for-model-access|urlcache'
  # Misc short noise
  binary_exclude+='|fo|json|nh|path|priv|private|sse|stream|token|user|ve)$'

  strings "$claude_bin" \
    | grep -oP '(?<=")/[a-z][-a-z]+(?=")' \
    | grep -vP "$binary_exclude" \
    | sort -u > "$tmpdir/binary_all.txt" &
fi

wait

# --- Source 1: Official docs ---
echo "=== Docs ==="
sort -u "$tmpdir/docs_commands.txt" "$tmpdir/docs_skills.txt" > "$tmpdir/docs_all.txt"

docs_count="$(wc -l < "$tmpdir/docs_all.txt")"
echo "Docs: $docs_count commands"

docs_new="$(comm -23 "$tmpdir/docs_all.txt" "$tmpdir/current.txt")"
docs_removed="$(comm -13 "$tmpdir/docs_all.txt" "$tmpdir/current.txt")"

if [[ -n "$docs_new" ]]; then
  echo "New (in docs, not in script):"
  echo "$docs_new"
fi

if [[ -n "$docs_removed" ]]; then
  echo "Removed (in script, not in docs):"
  echo "$docs_removed"
fi

if [[ -z "$docs_new" && -z "$docs_removed" ]]; then
  echo "No differences."
fi
echo

# --- Source 2: Claude binary (supplementary) ---
# The docs page can lag behind the actual binary. This section extracts
# quoted slash-command-like strings from the compiled Bun binary as a
# supplementary signal.  It has both false positives (non-command strings)
# and false negatives (many commands are not stored as simple quoted strings).
# Results should be verified manually.

echo "=== Binary (supplementary) ==="
if [[ ! -f "$tmpdir/binary_all.txt" ]]; then
  echo "Claude binary not found, skipping."
  exit 0
fi

echo "Binary: $claude_bin"

binary_count="$(wc -l < "$tmpdir/binary_all.txt")"
binary_new="$(comm -23 "$tmpdir/binary_all.txt" "$tmpdir/current.txt")"

echo "Candidates: $binary_count"

if [[ -n "$binary_new" ]]; then
  echo "New (in binary, not in script -- verify manually):"
  echo "$binary_new"
else
  echo "No new candidates."
fi
