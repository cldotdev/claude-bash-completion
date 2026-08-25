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
  _set_comp_line
  COMPREPLY=()
  _claude_bash_completion
}

# Helper: derive COMP_LINE and COMP_POINT from COMP_WORDS and COMP_CWORD,
# the way bash hands them to a completion function. The package parser reads
# the line rather than the words, so the fallback and the bash-completion
# paths only agree once both are set.
_set_comp_line() {
  COMP_LINE="${COMP_WORDS[*]}"
  local consumed="${COMP_WORDS[*]:0:COMP_CWORD+1}"
  COMP_POINT="${#consumed}"
}

# BASH_COMPLETION_LIB points at an installed bash_completion to exercise the
# package path; leaving it unset covers the fallback path instead.
setup() {
  if [[ -n "${BASH_COMPLETION_LIB:-}" ]]; then
    # shellcheck disable=SC1090
    source "$BASH_COMPLETION_LIB"
  fi
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

@test "--model completes with claude-opus-5 and its 1M variant" {
  _simulate_completion "claude" "--model" "" -- 2
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" claude-opus-5 "* ]]
  [[ "$joined" == *" claude-opus-5[1m] "* ]]
}

@test "--model completes with fable aliases" {
  _simulate_completion "claude" "--model" "" -- 2
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" fable "* ]]
  [[ "$joined" == *" fable[1m] "* ]]
  [[ "$joined" == *" claude-fable-5[1m] "* ]]
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
  [[ "${#COMPREPLY[@]}" -eq 7 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"default"* ]]
  [[ "$joined" == *"auto"* ]]
  [[ "$joined" == *"manual"* ]]
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

@test "/code-review completes with effort levels and ultra" {
  _simulate_completion "claude" "/code-review" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 6 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"low"* ]]
  [[ "$joined" == *"medium"* ]]
  [[ "$joined" == *"high"* ]]
  [[ "$joined" == *"xhigh"* ]]
  [[ "$joined" == *"max"* ]]
  [[ "$joined" == *"ultra"* ]]
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
  _set_comp_line
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

@test "_CLAUDE_BUILTIN_COMMANDS array has 125 entries" {
  [[ "${#_CLAUDE_BUILTIN_COMMANDS[@]}" -eq 125 ]]
}

@test "/artifact-diagramming is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/artifact-diagramming"* ]]
}

@test "/proactive is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/proactive"* ]]
}

@test "/team-onboarding is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/team-onboarding"* ]]
}

@test "/ultraplan is no longer in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" != *" /ultraplan "* ]]
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

@test "/run is in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" == *" /run "* ]]
}

@test "/run-skill-generator is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/run-skill-generator"* ]]
}

@test "/artifacts is in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" == *" /artifacts "* ]]
}

@test "/autocompact is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/autocompact"* ]]
}

@test "/design-sync is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/design-sync"* ]]
}

@test "commands behind a disabled feature flag are not in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" != *" /radio "* ]]
  [[ "$joined" != *" /web-setup "* ]]
}

@test "/teleport is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/teleport"* ]]
}

@test "/deep-research is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/deep-research"* ]]
}

@test "/subtask is in builtin commands" {
  local joined="${_CLAUDE_BUILTIN_COMMANDS[*]}"
  [[ "$joined" == *"/subtask"* ]]
}

@test "hidden slash command aliases are in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" == *" /name "* ]]
  [[ "$joined" == *" /routines "* ]]
  [[ "$joined" == *" /share "* ]]
  [[ "$joined" == *" /tp "* ]]
}

@test "/agents is no longer in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" != *" /agents "* ]]
}

@test "/remember is no longer in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" != *" /remember "* ]]
}

@test "/stuck is no longer in builtin commands" {
  local joined=" ${_CLAUDE_BUILTIN_COMMANDS[*]} "
  [[ "$joined" != *" /stuck "* ]]
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

@test "--forward-subagent-text is in flags" {
  local joined="${_CLAUDE_FLAGS[*]}"
  [[ "$joined" == *"--forward-subagent-text"* ]]
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

@test "--teleport is in flags" {
  local joined=" ${_CLAUDE_FLAGS[*]} "
  [[ "$joined" == *" --teleport "* ]]
}

@test "cloud session and context flags are in flags" {
  local joined=" ${_CLAUDE_FLAGS[*]} "
  [[ "$joined" == *" --autocompact "* ]]
  [[ "$joined" == *" --cloud "* ]]
  [[ "$joined" == *" --environment "* ]]
}

@test "--autocompact completes with window size values" {
  _simulate_completion "claude" "--autocompact" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 5 ]]
  local joined="${COMPREPLY[*]}"
  [[ "$joined" == *"auto"* ]]
  [[ "$joined" == *"100k"* ]]
  [[ "$joined" == *"1m"* ]]
}

@test "_CLAUDE_FLAGS array has 75 entries" {
  [[ "${#_CLAUDE_FLAGS[@]}" -eq 75 ]]
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

@test "background session subcommands are in subcommands" {
  local joined=" ${_CLAUDE_SUBCOMMANDS[*]} "
  [[ "$joined" == *" attach "* ]]
  [[ "$joined" == *" logs "* ]]
  [[ "$joined" == *" respawn "* ]]
  [[ "$joined" == *" rm "* ]]
  [[ "$joined" == *" stop "* ]]
}

@test "daemon and remote control subcommands are in subcommands" {
  local joined=" ${_CLAUDE_SUBCOMMANDS[*]} "
  [[ "$joined" == *" daemon "* ]]
  [[ "$joined" == *" rc "* ]]
  [[ "$joined" == *" remote-control "* ]]
}

@test "import and self-hosted-runner are in subcommands" {
  local joined=" ${_CLAUDE_SUBCOMMANDS[*]} "
  [[ "$joined" == *" import "* ]]
  [[ "$joined" == *" self-hosted-runner "* ]]
}

@test "_CLAUDE_SUBCOMMANDS array has 24 entries" {
  [[ "${#_CLAUDE_SUBCOMMANDS[@]}" -eq 24 ]]
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

# --- CLI subcommand trees ---

@test "claude mcp completes with its sub-subcommands" {
  _simulate_completion "claude" "mcp" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 10 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" add "* ]]
  [[ "$joined" == *" add-from-claude-desktop "* ]]
  [[ "$joined" == *" reset-project-choices "* ]]
}

@test "claude mcp add completes with its own flags" {
  _simulate_completion "claude" "mcp" "add" "--tr" -- 3
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--transport" ]]
}

@test "claude mcp add --transport completes with transport values" {
  _simulate_completion "claude" "mcp" "add" "--transport" "" -- 4
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" stdio "* ]]
  [[ "$joined" == *" sse "* ]]
  [[ "$joined" == *" http "* ]]
}

@test "claude mcp add --scope completes with scope values" {
  _simulate_completion "claude" "mcp" "add" "--scope" "" -- 4
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" local "* ]]
  [[ "$joined" == *" user "* ]]
  [[ "$joined" == *" project "* ]]
}

@test "claude plugin completes with the CLI sub-subcommands, not the slash ones" {
  _simulate_completion "claude" "plugin" "" -- 2
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" validate "* ]]
  [[ "$joined" == *" tag "* ]]
  [[ "$joined" == *" autoremove "* ]]
}

@test "claude plugin marketplace completes with its sub-subcommands" {
  _simulate_completion "claude" "plugin" "marketplace" "" -- 3
  [[ "${#COMPREPLY[@]}" -eq 5 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" add "* ]]
  [[ "$joined" == *" rm "* ]]
}

@test "claude plugin update completes with its own flags" {
  _simulate_completion "claude" "plugin" "update" "-" -- 3
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" -y "* ]]
  [[ "$joined" == *" --yes "* ]]
}

@test "claude plugin update --scope reaches the managed scope, enable does not" {
  _simulate_completion "claude" "plugin" "update" "--scope" "" -- 4
  [[ "${#COMPREPLY[@]}" -eq 4 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" managed "* ]]
  _simulate_completion "claude" "plugin" "enable" "--scope" "" -- 4
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  joined=" ${COMPREPLY[*]} "
  [[ "$joined" != *" managed "* ]]
}

@test "claude plugin eval init completes with its own flags" {
  _simulate_completion "claude" "plugin" "eval" "init" "--ba" -- 4
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--bare" ]]
}

@test "claude plugin eval completes with its own flags" {
  _simulate_completion "claude" "plugin" "eval" "--ev" -- 3
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--eval-dir" ]]
}

@test "claude auth completes with its sub-subcommands" {
  _simulate_completion "claude" "auth" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" login "* ]]
  [[ "$joined" == *" status "* ]]
}

@test "claude auth login completes with its own flags" {
  _simulate_completion "claude" "auth" "login" "--c" -- 3
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" --claudeai "* ]]
  [[ "$joined" == *" --console "* ]]
}

@test "claude auto-mode completes with its sub-subcommands" {
  _simulate_completion "claude" "auto-mode" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 4 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" critique "* ]]
  [[ "$joined" == *" defaults "* ]]
}

@test "claude daemon completes with its sub-subcommands" {
  _simulate_completion "claude" "daemon" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 5 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" uninstall "* ]]
}

@test "claude project purge completes with its own flags" {
  _simulate_completion "claude" "project" "purge" "--d" -- 3
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--dry-run" ]]
}

@test "claude import completes with agent sources" {
  _simulate_completion "claude" "import" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" codex "* ]]
  [[ "$joined" == *" gemini "* ]]
}

@test "claude install completes with version targets" {
  _simulate_completion "claude" "install" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" stable "* ]]
  [[ "$joined" == *" latest "* ]]
}

@test "claude remote-control completes with its own flags" {
  _simulate_completion "claude" "remote-control" "--s" -- 2
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" --session-id "* ]]
  [[ "$joined" == *" --spawn "* ]]
}

@test "claude rc --spawn completes with spawn modes" {
  _simulate_completion "claude" "rc" "--spawn" "" -- 3
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" same-dir "* ]]
  [[ "$joined" == *" worktree "* ]]
  [[ "$joined" == *" session "* ]]
}

@test "claude self-hosted-runner completes with its own flags" {
  _simulate_completion "claude" "self-hosted-runner" "--proxy-" -- 2
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" --proxy-authorization-command "* ]]
  [[ "$joined" == *" --proxy-authorization-file "* ]]
  _simulate_completion "claude" "self-hosted-runner" "--defer" -- 2
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--defer-shutdown-max-min" ]]
}

@test "subcommand flags replace the global flag list" {
  _simulate_completion "claude" "ultrareview" "--t" -- 2
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--timeout" ]]
}

@test "subcommands still complete after a global flag and its value" {
  _simulate_completion "claude" "--model" "opus" "mc" -- 3
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "mcp" ]]
}

@test "subcommands still complete after a valueless global flag" {
  _simulate_completion "claude" "--verbose" "doc" -- 2
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "doctor" ]]
}

@test "a slash command suppresses subcommand completion" {
  _simulate_completion "claude" "/help" "" -- 2
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" != *" doctor "* ]]
  [[ "$joined" != *" mcp "* ]]
}

# --- tool name values ---

@test "--tools completes with built-in tool names" {
  _simulate_completion "claude" "--tools" "" -- 2
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" Bash "* ]]
  [[ "$joined" == *" Read "* ]]
  [[ "$joined" == *" Skill "* ]]
  [[ "$joined" == *" default "* ]]
}

@test "--allowedTools and --disallowed-tools complete with tool names" {
  _simulate_completion "claude" "--allowedTools" "Web" -- 2
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  _simulate_completion "claude" "--disallowed-tools" "Web" -- 2
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
}

@test "variadic flags keep completing past their first value" {
  _simulate_completion "claude" "--tools" "Bash" "Rea" -- 3
  [[ "${#COMPREPLY[@]}" -eq 3 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" Read "* ]]
  [[ "$joined" == *" ReadMcpResourceTool "* ]]
}

@test "an optional-value flag followed by a dash completes flags" {
  _simulate_completion "claude" "--resume" "--mod" -- 2
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "--model" ]]
}

# --- session ID values ---

# Build a fake ~/.claude/projects tree: two project directories, one session
# each, plus a non-transcript file that must not be offered.
_make_sessions() {
  HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/.claude/projects/-home-user-alpha" \
    "$HOME/.claude/projects/-home-user-beta"
  touch -t 202601010000 "$HOME/.claude/projects/-home-user-alpha/aaaa1111-old.jsonl"
  touch -t 202602010000 "$HOME/.claude/projects/-home-user-beta/aaaa2222-new.jsonl"
  touch "$HOME/.claude/projects/-home-user-beta/notes.txt"
}

@test "--resume completes with session ids from every project directory" {
  _make_sessions
  _simulate_completion "claude" "--resume" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  local joined=" ${COMPREPLY[*]} "
  [[ "$joined" == *" aaaa1111-old "* ]]
  [[ "$joined" == *" aaaa2222-new "* ]]
  [[ "$joined" != *" notes "* ]]
}

@test "-r completes session ids newest first" {
  _make_sessions
  _simulate_completion "claude" "-r" "aaaa" -- 2
  [[ "${#COMPREPLY[@]}" -eq 2 ]]
  [[ "${COMPREPLY[0]}" == "aaaa2222-new" ]]
  [[ "${COMPREPLY[1]}" == "aaaa1111-old" ]]
}

@test "--resume completes nothing when no session has been recorded" {
  HOME="$BATS_TEST_TMPDIR/empty-home"
  mkdir -p "$HOME"
  _simulate_completion "claude" "--resume" "" -- 2
  [[ "${#COMPREPLY[@]}" -eq 0 ]]
}

# --- complete registration ---

@test "complete registration includes -o default" {
  local reg
  reg=$(complete -p claude 2>/dev/null)
  [[ "$reg" == *"-o default"* ]]
}

# --- opening quotes ---

@test "slash commands complete inside an opening single quote" {
  _simulate_completion "claude" "'/hel" -- 1
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "/help" ]]
}

@test "slash commands complete inside an opening double quote" {
  _simulate_completion "claude" '"/hel' -- 1
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "/help" ]]
}

@test "an opening quote is dropped only ahead of a slash command" {
  _simulate_completion "claude" "'--mod" -- 1
  [[ "${#COMPREPLY[@]}" -eq 0 ]]
}

# --- surrounding tools ---

@test "slash command completion survives git failing" {
  local stub="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$stub"
  printf '#!/bin/sh\nexit 128\n' > "$stub/git"
  chmod +x "$stub/git"
  PATH="$stub:$PATH" _simulate_completion "claude" "/hel" -- 1
  [[ "${#COMPREPLY[@]}" -eq 1 ]]
  [[ "${COMPREPLY[0]}" == "/help" ]]
}

# --- sourcing ---

@test "sourcing the script defines no claude function" {
  run bash -c 'source claude-completion.bash; type -t claude'
  [[ "$output" != "function" ]]
}

@test "sourcing the script twice is silent" {
  run bash -c 'source claude-completion.bash; source claude-completion.bash'
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}
