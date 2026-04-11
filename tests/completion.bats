#!/usr/bin/env bats

# Helper: simulate bash completion at a given cursor position.
# Usage: _simulate_completion "word0" "word1" ... -- cword_index
# Sets COMP_WORDS, COMP_CWORD, calls the completion function, and
# leaves COMPREPLY populated for assertions.
_simulate_completion() {
  local words=()
  local cword=""
  local parsing_words=1
  for arg in "$@"; do
    if [[ "$arg" == "--" ]]; then
      parsing_words=0
      continue
    fi
    if [[ "$parsing_words" -eq 1 ]]; then
      words+=("$arg")
    else
      cword="$arg"
    fi
  done

  COMP_WORDS=("${words[@]}")
  COMP_CWORD="$cword"
  COMPREPLY=()
  _claude_bash_completion
}

setup() {
  source "$BATS_TEST_DIRNAME/../claude-completion.bash"
}

# --- prev variable ---

@test "prev variable is defined inside completion function" {
  # Verify that the function source contains prev assignment
  local fn_body
  fn_body=$(declare -f _claude_bash_completion)
  [[ "$fn_body" == *'prev="${COMP_WORDS[COMP_CWORD-1]}"'* ]]
}

# --- flag value completions ---

@test "--model completes with model values" {
  _simulate_completion "claude" "--model" "" -- 2
  [[ "${#COMPREPLY[@]}" -gt 0 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"sonnet"* ]]
  [[ "$joined" == *"opus"* ]]
  [[ "$joined" == *"haiku"* ]]
  [[ "$joined" == *"default"* ]]
}

@test "--fallback-model completes with model values" {
  _simulate_completion "claude" "--fallback-model" "" -- 2
  [[ "${#COMPREPLY[@]}" -gt 0 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"sonnet"* ]]
}

@test "--output-format completes with format values" {
  _simulate_completion "claude" "--output-format" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"text"* ]]
  [[ "$joined" == *"json"* ]]
  [[ "$joined" == *"stream-json"* ]]
}

@test "--input-format completes with format values" {
  _simulate_completion "claude" "--input-format" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"text"* ]]
  [[ "$joined" == *"stream-json"* ]]
}

@test "--permission-mode completes with mode values" {
  _simulate_completion "claude" "--permission-mode" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 6 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"default"* ]]
  [[ "$joined" == *"auto"* ]]
  [[ "$joined" == *"plan"* ]]
}

@test "--effort completes with effort levels" {
  _simulate_completion "claude" "--effort" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 4 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"low"* ]]
  [[ "$joined" == *"medium"* ]]
  [[ "$joined" == *"high"* ]]
  [[ "$joined" == *"max"* ]]
}

@test "--setting-sources completes with source values" {
  _simulate_completion "claude" "--setting-sources" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"user"* ]]
  [[ "$joined" == *"project"* ]]
  [[ "$joined" == *"local"* ]]
}

@test "--model filters by partial input" {
  _simulate_completion "claude" "--model" "son" -- 2
  [[ "${#COMPREPLY[@]}" -ge 1 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"sonnet"* ]]
  # Should not contain non-matching values
  [[ "$joined" != *"opus"* ]]
}

@test "flag value completion returns 0 and does not fall through" {
  _simulate_completion "claude" "--effort" "" -- 2
  # Should have completions (not fall through to slash commands)
  [[ "${#COMPREPLY[@]}" -gt 0 ]]
  # Should not contain slash commands
  local joined="${COMPREPLY[*]}"
  [[ "$joined" != *"/help"* ]]
}

# --- flag completions ---

@test "cur starting with -- completes flags" {
  _simulate_completion "claude" "--mo" -- 1
  [[ "${#COMPREPLY[@]}" -ge 1 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"--model"* ]]
}

@test "cur starting with - completes short flags" {
  _simulate_completion "claude" "-" -- 1
  [[ "${#COMPREPLY[@]}" -gt 0 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"-h"* ]]
  [[ "$joined" == *"-v"* ]]
  [[ "$joined" == *"-p"* ]]
}

@test "flag completion does not include slash commands" {
  _simulate_completion "claude" "--" -- 1
  local joined="${COMPREPLY[*]}"
  [[ "$joined" != *"/help"* ]]
}

@test "_CLAUDE_FLAGS array has 64 entries" {
  [[ "${#_CLAUDE_FLAGS[@]}" -eq 64 ]]
}

@test "_CLAUDE_FLAGS is readonly" {
  run bash -c 'source claude-completion.bash; _CLAUDE_FLAGS=(foo)'
  [[ "$status" -ne 0 ]]
}

# --- subcommand completions ---

@test "subcommand completes at position 1" {
  _simulate_completion "claude" "up" -- 1
  [[ "${#COMPREPLY[@]}" -ge 1 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"update"* ]]
  [[ "$joined" == *"upgrade"* ]]
}

@test "subcommand completion includes all subcommands with empty input" {
  _simulate_completion "claude" "" -- 1
  # Should contain subcommands (among possibly other completions)
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"doctor"* ]]
  [[ "$joined" == *"mcp"* ]]
  [[ "$joined" == *"auth"* ]]
}

@test "subcommand completion only at position 1" {
  # At position 2, subcommands should not appear
  _simulate_completion "claude" "--model" "doc" -- 2
  local joined="${COMPREPLY[*]}"
  [[ "$joined" != *"doctor"* ]]
}

@test "_CLAUDE_SUBCOMMANDS array has 11 entries" {
  [[ "${#_CLAUDE_SUBCOMMANDS[@]}" -eq 11 ]]
}

@test "_CLAUDE_SUBCOMMANDS is readonly" {
  run bash -c 'source claude-completion.bash; _CLAUDE_SUBCOMMANDS=(foo)'
  [[ "$status" -ne 0 ]]
}

@test "slash command completion still works at position 1" {
  _simulate_completion "claude" "/hel" -- 1
  [[ "${#COMPREPLY[@]}" -ge 1 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"/help"* ]]
}

@test "flag completion still works at position 1" {
  _simulate_completion "claude" "--mod" -- 1
  [[ "${#COMPREPLY[@]}" -ge 1 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"--model"* ]]
}

# --- complete registration ---

@test "complete registration includes -o default" {
  local reg
  reg=$(complete -p claude 2>/dev/null)
  [[ "$reg" == *"-o default"* ]]
}
