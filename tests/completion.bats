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

@test "--model completes with claude-fable-5" {
  _simulate_completion "claude" "--model" "" -- 2
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"claude-fable-5"* ]]
}

@test "--model completes with claude-sonnet-5" {
  _simulate_completion "claude" "--model" "" -- 2
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"claude-sonnet-5"* ]]
}

@test "--fallback-model completes with model values" {
  _simulate_completion "claude" "--fallback-model" "" -- 2
  [[ "${#COMPREPLY[@]}" -gt 0 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"sonnet"* ]]
}

@test "/model completes with model values" {
  _simulate_completion "claude" "/model" "" -- 2
  [[ "${#COMPREPLY[@]}" -gt 0 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"sonnet"* ]]
  [[ "$joined" == *"opus"* ]]
  [[ "$joined" == *"haiku"* ]]
  [[ "$joined" == *"default"* ]]
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
  [[ "${#COMPREPLY[@]}" -eq 5 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"low"* ]]
  [[ "$joined" == *"medium"* ]]
  [[ "$joined" == *"high"* ]]
  [[ "$joined" == *"xhigh"* ]]
  [[ "$joined" == *"max"* ]]
}

@test "/code-review completes with effort levels" {
  _simulate_completion "claude" "/code-review" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 5 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"low"* ]]
  [[ "$joined" == *"medium"* ]]
  [[ "$joined" == *"high"* ]]
  [[ "$joined" == *"xhigh"* ]]
  [[ "$joined" == *"max"* ]]
}

@test "/code-review with --c completes to --comment" {
  _simulate_completion "claude" "/code-review" "--c" -- 2
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--comment" ]]
}

@test "/code-review after effort with --c completes to --comment" {
  _simulate_completion "claude" "/code-review" "high" "--c" -- 3
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--comment" ]]
}

@test "/code-review with --f completes to --fix" {
  _simulate_completion "claude" "/code-review" "--f" -- 2
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--fix" ]]
}

@test "/code-review with -- completes both --comment and --fix" {
  # Set arrays directly: _simulate_completion treats "--" as its own
  # word/cword separator, so a literal "--" word cannot pass through it.
  COMP_WORDS=(claude /code-review --)
  COMP_CWORD=2
  COMPREPLY=()
  _claude_bash_completion
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"--comment"* ]]
  [[ "$joined" == *"--fix"* ]]
}

@test "/plugin completes with subcommands" {
  _simulate_completion "claude" "/plugin" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 6 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"install"* ]]
  [[ "$joined" == *"uninstall"* ]]
  [[ "$joined" == *"enable"* ]]
  [[ "$joined" == *"disable"* ]]
  [[ "$joined" == *"list"* ]]
  [[ "$joined" == *"marketplace"* ]]
}

@test "/plugin with inst completes to install only" {
  _simulate_completion "claude" "/plugin" "inst" -- 2
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "install" ]]
}

@test "/plugin marketplace completes with sub-subcommands" {
  _simulate_completion "claude" "/plugin" "marketplace" "" -- 3
  [[ "${#COMPREPLY[@]}" -eq 4 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"add"* ]]
  [[ "$joined" == *"remove"* ]]
  [[ "$joined" == *"list"* ]]
  [[ "$joined" == *"update"* ]]
}

@test "/plugin subcommand completion does not include slash commands" {
  _simulate_completion "claude" "/plugin" "" -- 2
  local joined="${COMPREPLY[*]}"
  [[ "$joined" != *"/help"* ]]
}

@test "marketplace sub-subcommands only complete within /plugin context" {
  _simulate_completion "claude" "/code-review" "marketplace" "" -- 3
  local joined="${COMPREPLY[*]}"
  [[ "$joined" != *"add"* ]]
  [[ "$joined" != *"update"* ]]
}

@test "flag completion outside /code-review does not include --comment" {
  _simulate_completion "claude" "--c" -- 1
  local joined="${COMPREPLY[*]}"
  [[ "$joined" != *"--comment"* ]]
  [[ "$joined" == *"--chrome"* ]]
  [[ "$joined" == *"--continue"* ]]
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

@test "_CLAUDE_BUILTIN_COMMANDS array has 111 entries" {
  [[ "${#_CLAUDE_BUILTIN_COMMANDS[@]}" -eq 111 ]]
}

@test "_CLAUDE_BUILTIN_COMMANDS is readonly" {
  run bash -c 'source claude-completion.bash; _CLAUDE_BUILTIN_COMMANDS=(foo)'
  [[ "$status" -ne 0 ]]
}

@test "/proactive is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/proactive"* ]]
}

@test "/team-onboarding is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/team-onboarding"* ]]
}

@test "/ultraplan is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/ultraplan"* ]]
}

@test "/recap is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/recap"* ]]
}

@test "/undo is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/undo"* ]]
}

@test "/focus is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/focus"* ]]
}

@test "/tui is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/tui"* ]]
}

@test "/fewer-permission-prompts is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/fewer-permission-prompts"* ]]
}

@test "/reload-skills is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/reload-skills"* ]]
}

@test "/simplify is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/simplify"* ]]
}

@test "/cd is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/cd"* ]]
}

@test "/background is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/background"* ]]
}

@test "/bg is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/bg"* ]]
}

@test "/dataviz is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/dataviz"* ]]
}

@test "/checkup is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/checkup"* ]]
}

@test "/agents is no longer in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" != *" /agents "* ]]
}

@test "--safe-mode is in flags" {
  local joined="${_CLAUDE_FLAGS[*]}"
  [[ "$joined" == *"--safe-mode"* ]]
}

@test "--bg and --background are in flags" {
  local joined="${_CLAUDE_FLAGS[*]}"
  [[ "$joined" == *"--bg"* ]]
  [[ "$joined" == *"--background"* ]]
}

@test "--ax-screen-reader is in flags" {
  local joined="${_CLAUDE_FLAGS[*]}"
  [[ "$joined" == *"--ax-screen-reader"* ]]
}

@test "--plugin-url is in flags" {
  local joined="${_CLAUDE_FLAGS[*]}"
  [[ "$joined" == *"--plugin-url"* ]]
}

@test "--remote-control is in flags" {
  local joined=" ${_CLAUDE_FLAGS[*]} "
  [[ "$joined" == *" --remote-control "* ]]
}

@test "--mcp-debug is no longer in flags" {
  local joined=" ${_CLAUDE_FLAGS[*]} "
  [[ "$joined" != *" --mcp-debug "* ]]
}

@test "--prompt-suggestions completes with choice values" {
  _simulate_completion "claude" "--prompt-suggestions" "" -- 2
  [[ "${#COMPREPLY[@]}" -gt 0 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"true"* ]]
  [[ "$joined" == *"false"* ]]
}

@test "_CLAUDE_FLAGS array has 70 entries" {
  [[ "${#_CLAUDE_FLAGS[@]}" -eq 70 ]]
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

@test "gateway, project, and ultrareview are in subcommands" {
  local joined="${_CLAUDE_SUBCOMMANDS[*]}"
  [[ "$joined" == *"gateway"* ]]
  [[ "$joined" == *"project"* ]]
  [[ "$joined" == *"ultrareview"* ]]
}

@test "_CLAUDE_SUBCOMMANDS array has 14 entries" {
  [[ "${#_CLAUDE_SUBCOMMANDS[@]}" -eq 14 ]]
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
