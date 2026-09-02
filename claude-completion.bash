# ========================================
# Claude Bash Completion
# ========================================

# Extract the name field from YAML frontmatter (between --- markers).
# Leaves the name in REPLY, empty when there is no frontmatter or no name.
# The name comes back in REPLY rather than on stdout because the caller runs
# this once per discovered file, and a command substitution would fork a
# subshell every time even though nothing here execs.
_claude_frontmatter_name() {
  local file="$1" line opened=""
  REPLY=""
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$opened" ]]; then
      [[ "$line" == "---" ]] || return 0
      opened=1
      continue
    fi
    [[ "$line" == "---" ]] && return 0
    [[ "$line" == name:* ]] || continue
    REPLY="${line#name:}"
    while [[ "$REPLY" == " "* ]]; do
      REPLY="${REPLY# }"
    done
    REPLY="${REPLY#[\"\']}"
    REPLY="${REPLY%[\"\']}"
    return 0
  done < "$file"
}

# Discover custom commands/skills from a directory.
# Uses frontmatter name if available, falls back to path-based derivation.
# Args: base_dir find_pattern strip_suffix
_claude_discover_commands() {
  local base_dir="$1" find_pattern="$2" strip_suffix="$3"
  find -L "$base_dir" -type f -name "$find_pattern" 2>/dev/null | while read -r file; do
    _claude_frontmatter_name "$file"
    if [[ -n "$REPLY" ]]; then
      echo "/$REPLY"
    else
      local rel="${file#"$base_dir"/}"
      rel="${rel%"$strip_suffix"}"
      rel="${rel//\//:}"
      echo "/$rel"
    fi
  done
}

# Built-in slash commands (130 commands as of v2.1.258)
_CLAUDE_BUILTIN_COMMANDS=(
  /add-dir /advisor /allowed-tools /android
  /artifact-capabilities /artifact-design /artifact-diagramming /artifacts
  /autocompact /autofix-pr
  /background /bashes /batch /bg /branch /brief /btw /bug
  /cd /checkpoint /checkup /chrome /claude-api /claude-in-chrome /clear /code-review /color
  /compact /config /context /continue /copy /cost
  /dataviz /debug /deep-research /design /design-login /design-sync /diff /doctor
  /effort /exit /export
  /fast /feedback /fewer-permission-prompts /focus /fork
  /goal
  /help /hooks
  /ide /init /insights /install-github-app /install-slack-app /ios
  /keybindings /keybindings-help
  /list-agents /login /logout /loop
  /marketplace /mcp /memory /mobile /model /name /new
  /passes /peers /permissions /plan /plugin /plugins /powerup
  /privacy-settings /proactive /quit
  /radio /rc /recap /release-notes /reload-plugins /reload-skills /remote-control
  /remote-env /rename /reset /resume /review /rewind /routines /run /run-skill-generator
  /sandbox /schedule /scroll-speed /security-review /settings
  /setup-bedrock /setup-vertex /share
  /simplify /skills /stats /status /statusline /stickers /subtask
  /tasks /team-onboarding /teleport /terminal-setup /theme /tp /tui
  /ultrareview /undo /update-config /upgrade /usage /usage-credits
  /verify /voice /web-setup /workflow-authoring /workflows
)

# CLI flags (77 flags as of v2.1.258)
_CLAUDE_FLAGS=(
  --add-dir
  --agent --agents
  --allow-dangerously-skip-permissions
  --allowedTools --allowed-tools
  --append-system-prompt --append-system-prompt-file
  --autocompact --ax-screen-reader
  --background --bare --betas --bg --brief
  --chrome --cloud
  -c --continue
  --dangerously-skip-permissions
  -d --debug --debug-file
  --disable-slash-commands
  --disallowedTools --disallowed-tools
  --effort --environment
  --exclude-dynamic-system-prompt-sections
  --fallback-model --file --fork-session --forward-subagent-text --from-pr
  -h --help
  --ide
  --include-hook-events --include-partial-messages
  --input-format
  --json-schema
  --max-budget-usd --mcp-config --model
  -n --name --no-chrome --no-session-persistence
  --output-format
  --permission-mode --plugin-dir --plugin-url
  -p --print --prompt-suggestions
  --remote-control --remote-control-session-name-prefix --replay-user-messages
  --restricted
  -r --resume
  --safe-mode
  --session-id --setting-sources --settings --strict-mcp-config
  --system-prompt --system-prompt-file --system-prompt-snapshot
  --teleport --tmux --tools
  --verbose
  -v --version
  -w --worktree
)

# CLI subcommands (24 subcommands as of v2.1.258)
_CLAUDE_SUBCOMMANDS=(
  agents attach auth auto-mode daemon doctor gateway import install
  logs mcp plugin plugins project rc remote-control respawn rm
  self-hosted-runner setup-token stop ultrareview update upgrade
)

# Effort levels (shared by --effort flag and /code-review command)
_CLAUDE_EFFORT_LEVELS=(low medium high xhigh max)

# Flags accepted by the /code-review command (shared by both flag paths)
_CLAUDE_CODE_REVIEW_FLAGS=(--comment --fix)

# Positional values accepted by the /code-review command: the effort levels
# plus "ultra", which escalates the review to the cloud-hosted /ultrareview
_CLAUDE_CODE_REVIEW_ARGS=("${_CLAUDE_EFFORT_LEVELS[@]}" ultra)

# Subcommands accepted by the /plugin command
_CLAUDE_PLUGIN_SUBCOMMANDS=(install uninstall enable disable list marketplace)

# Sub-subcommands accepted by /plugin marketplace
_CLAUDE_PLUGIN_MARKETPLACE_SUBCOMMANDS=(add remove list update)

# Flags that consume the following word as their value. Scanning for the
# subcommand skips those values, so `claude --model opus mcp` still resolves to
# `mcp`. Flags whose value is optional belong here too: when the next word
# starts with a dash it is read as the next flag rather than as the value.
_CLAUDE_VALUE_FLAGS=(
  --add-dir --agent --agents --allowedTools --allowed-tools
  --append-system-prompt --append-system-prompt-file --autocompact
  --betas --cloud -d --debug --debug-file --disallowedTools --disallowed-tools
  --effort --environment --fallback-model --file --from-pr
  --input-format --json-schema --max-budget-usd --mcp-config --model
  -n --name --output-format --permission-mode --plugin-dir --plugin-url
  --prompt-suggestions --remote-control --remote-control-session-name-prefix
  -r --resume --session-id --setting-sources --settings
  --system-prompt --system-prompt-file --system-prompt-snapshot --teleport
  --tmux --tools
  -w --worktree
)

# Flags that take several space-separated values. Every one of those words
# belongs to the flag, so the flag governs completion until the next one appears.
_CLAUDE_VARIADIC_FLAGS=(
  --add-dir --allowedTools --allowed-tools --betas
  --disallowedTools --disallowed-tools --file --tools
)

# Built-in tool names accepted by --tools, --allowedTools, and --disallowedTools.
# `claude --help` carries no listing and the CLI accepts unknown names without
# complaint, so this mirrors the built-in section of the tool ordering table in
# the v2.1.258 binary. MCP and self-hosted-runner tools are left out: those
# names come from a connected server, not from the build. "default" comes from
# the --tools help text.
_CLAUDE_TOOL_NAMES=(
  Agent AskUserQuestion Artifact
  Bash BashOutput Brief
  ClaudeDesign ConnectGitHub CronCreate CronDelete CronList
  DesignSync
  Edit EnterWorktree ExitWorktree
  Glob Grep
  KillShell
  LS LSP ListAgents ListConnectors ListMcpResourcesTool ListPeers
  ListPlugins ListSkills
  Monitor MultiEdit
  NotebookEdit NotebookRead
  ObserverReport
  PowerShell Projects PushNotification
  REPL Read ReadMcpResourceDirTool ReadMcpResourceTool RefreshMcpTools
  RemoteTrigger ReportFindings
  ScheduleWakeup SearchMcpRegistry SearchPlugins SearchSkills
  SendFeedback SendFile SendMessage SendUserFile SendUserMessage
  Skill Snip SubscribePR SuggestConnectors SuggestPluginInstall SuggestSkills
  Task TaskCreate TaskGet TaskList TaskOutput TaskStop TaskUpdate
  Tmux TodoWrite
  WebBrowser WebFetch WebSearch Workflow Write
  default
)

# Sub-subcommands of the CLI subcommands that have them. `claude plugin` and
# `claude plugin marketplace` accept more than their /plugin slash counterparts,
# so they get their own lists rather than sharing those above.
_CLAUDE_AUTH_SUBCOMMANDS=(login logout status)
_CLAUDE_AUTO_MODE_SUBCOMMANDS=(config critique defaults reset)
_CLAUDE_DAEMON_SUBCOMMANDS=(logs run status stop uninstall)
_CLAUDE_MCP_SUBCOMMANDS=(
  add add-from-claude-desktop add-json get list login logout remove
  reset-project-choices serve
)
_CLAUDE_PLUGIN_CLI_SUBCOMMANDS=(
  autoremove details disable enable eval i init install list marketplace new
  prune remove tag uninstall update validate
)
_CLAUDE_PLUGIN_CLI_MARKETPLACE_SUBCOMMANDS=(add list remove rm update)
_CLAUDE_PROJECT_SUBCOMMANDS=(purge)

# How many of a project's transcripts are read for their titles. The live
# title is the last record in a transcript, so every transcript opened is read
# to the end: 50 of them come to tens of megabytes on a well-worked project,
# and all of them to hundreds.
_CLAUDE_TITLE_SCAN=50

# Report whether a flag appears in the given list.
# Args: flag, then the list entries.
_claude_flag_in() {
  local candidate="$1" flag
  shift
  for flag in "$@"; do
    [[ "$flag" == "$candidate" ]] && return 0
  done
  return 1
}

# Report whether a flag consumes the following word as its value.
_claude_is_value_flag() {
  _claude_flag_in "$1" "${_CLAUDE_VALUE_FLAGS[@]}"
}

# Find the first word at or after `start` that is neither a flag nor a flag's
# value, and report it in _claude_word and _claude_word_idx.
# Args: start_index, then every word up to (not including) the cursor.
_claude_find_word() {
  local start="$1"
  shift
  local -a scanned=("$@")
  local i
  _claude_word=""
  _claude_word_idx=0
  for ((i = start; i < ${#scanned[@]}; i++)); do
    if [[ "${scanned[i]}" == -* ]]; then
      if _claude_is_value_flag "${scanned[i]}" && [[ "${scanned[i + 1]-}" != -* ]]; then
        ((i++))
      fi
      continue
    fi
    _claude_word="${scanned[i]}"
    _claude_word_idx="$i"
    return 0
  done
  return 1
}

# Complete paths through bash-completion, which escapes spaces and other
# metacharacters, falling back to compgen where it is not loaded. Version 2.12
# renamed _filedir; the old name survives only in a compat file that a
# distribution may or may not ship, so reach for the current name first.
_claude_filedir() {
  if declare -F _comp_compgen >/dev/null; then
    _comp_compgen -a filedir "$@"
  elif declare -F _filedir >/dev/null; then
    _filedir "$@"
  elif [[ "${1-}" == "-d" ]]; then
    mapfile -t COMPREPLY < <(compgen -d -- "$cur")
  else
    mapfile -t COMPREPLY < <(compgen -f -- "$cur")
  fi
}

# Hand the candidates back in the order they were built rather than sorted.
# compopt fails when called outside a completion; the ordering is a nicety,
# not a reason to hand the caller a failure.
_claude_keep_order() {
  compopt -o nosort 2>/dev/null || true
}

# Offer a word list, keeping the order it is written in, so ordered lists such
# as effort levels do not come back alphabetized.
# Args: word list, current word.
_claude_reply_ordered() {
  mapfile -t COMPREPLY < <(compgen -W "$1" -- "$2")
  _claude_keep_order
}

# Offer a subcommand's own flags when a flag is being typed, and its
# sub-subcommands or positional values otherwise.
# Args: current word, flag list, word list (empty when the subcommand takes
# only a free-form argument).
_claude_reply_subcommand() {
  if [[ "$1" == -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "$2" -- "$1")
  else
    mapfile -t COMPREPLY < <(compgen -W "${3-}" -- "$1")
  fi
}

# Report the transcript directory for a working directory in REPLY, empty
# where there is none. Claude Code names it after the directory with every
# character outside [a-zA-Z0-9] turned into a dash, keeping the first 200 and
# appending a hash of the path once that runs longer. The hash cannot be
# reproduced here, so a long path is matched on the part that can be.
# Args: working directory.
_claude_project_dir() {
  local encoded="${1//[^a-zA-Z0-9]/-}" root="$HOME/.claude/projects"
  local -a matches
  REPLY=""
  if [[ "${#encoded}" -gt 200 ]]; then
    matches=("$root/${encoded:0:200}"-*/)
    if [[ -d "${matches[0]-}" ]]; then
      REPLY="${matches[0]%/}"
    fi
  elif [[ -d "$root/$encoded" ]]; then
    REPLY="$root/$encoded"
  fi
  return 0
}

# Collect the titles of the current directory's sessions into _claude_titles,
# newest first. Claude Code resolves a title only among the sessions it holds
# for the working directory, so titles from elsewhere are left out; a title
# reached from the wrong directory would open an empty picker rather than
# resume anything. The last record in a transcript is the live title, an
# earlier one having been replaced by /rename.
_claude_session_titles() {
  local dir listing line rest file title REPLY
  local -a files=()
  local -A latest=() emitted=()
  _claude_titles=()
  # Claude Code records the directory as the kernel reports it, which is what
  # PWD holds unless the shell walked in through a symlink. Asking the shell
  # to resolve one costs a subshell, so PWD is tried first and paid for only
  # when it turns up nothing.
  _claude_project_dir "$PWD"
  dir="$REPLY"
  if [[ -z "$dir" ]]; then
    _claude_project_dir "$(pwd -P)"
    dir="$REPLY"
  fi
  [[ -n "$dir" ]] || return 0
  listing=$(command ls -t "$dir"/*.jsonl 2>/dev/null)
  # Handed no files at all, grep would read the terminal it inherited.
  [[ -n "$listing" ]] || return 0
  mapfile -t files <<< "$listing"
  files=("${files[@]:0:$_CLAUDE_TITLE_SCAN}")
  listing=$(grep -H -o '"customTitle":"[^"]*"' "${files[@]}" 2>/dev/null)
  [[ -n "$listing" ]] || return 0
  while IFS= read -r line; do
    rest="${line#"$dir"/}"
    file="${rest%%:*}"
    title="${rest#*:\"customTitle\":\"}"
    latest["$file"]="${title%\"}"
  done <<< "$listing"
  for file in "${files[@]}"; do
    title="${latest["${file##*/}"]-}"
    if [[ -n "$title" && -z "${emitted["$title"]-}" ]]; then
      emitted["$title"]=1
      _claude_titles+=("$title")
    fi
  done
  return 0
}

# Rebuild words, cword, cur, and prev with colon-separated words kept whole.
# Stands in for the -n option of the bash-completion parsers where the package
# is absent. COMP_WORDS alone cannot tell `a:b` from `a : b`, so adjacency is
# read off COMP_LINE; where the shell leaves it unset, nothing is joined and
# the raw arrays come through as before.
_claude_word_list() {
  local i word rest gap adjacent last pos=0
  words=()
  cword=-1
  for ((i = 0; i < ${#COMP_WORDS[@]}; i++)); do
    word="${COMP_WORDS[i]}"
    adjacent=""
    if [[ -n "$word" && "${COMP_LINE:pos}" == *"$word"* ]]; then
      rest="${COMP_LINE:pos}"
      gap="${rest%%"$word"*}"
      pos=$((pos + ${#gap} + ${#word}))
      [[ -n "$gap" ]] || adjacent=1
    fi
    last=$((${#words[@]} - 1))
    if [[ -n "$adjacent" && "$last" -ge 0 ]] &&
      [[ "${words[last]}" == *: || "$word" == :* ]]; then
      words[last]+="$word"
    else
      words+=("$word")
    fi
    if [[ "$i" -eq "$COMP_CWORD" ]]; then
      cword=$((${#words[@]} - 1))
    fi
  done
  # A cursor past the last word sits on an empty one, which is where bash puts
  # it after a trailing space.
  if [[ "$cword" -lt 0 ]]; then
    cword=${#words[@]}
  fi
  cur="${words[cword]-}"
  prev=""
  if [[ "$cword" -gt 0 ]]; then
    prev="${words[cword - 1]}"
  fi
}

# Drop the part of each candidate that bash will not replace. Bash rewrites
# only the text after the last COMP_WORDBREAKS character, so a candidate that
# still carries what precedes it is inserted on top of what is already typed.
# Args: current word.
_claude_ltrim_colon() {
  local prefix i
  [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]] || return 0
  if declare -F _comp_ltrim_colon_completions >/dev/null; then
    _comp_ltrim_colon_completions "$1"
  elif declare -F __ltrim_colon_completions >/dev/null; then
    __ltrim_colon_completions "$1"
  else
    prefix="${1%"${1##*:}"}"
    for i in "${!COMPREPLY[@]}"; do
      COMPREPLY[i]="${COMPREPLY[i]#"$prefix"}"
    done
  fi
}

# Offer values that are free-form text rather than identifiers, keeping the
# order they arrive in. compgen -W is no good for these: it splits on spaces
# and expands what it is given, so a session title holding a command
# substitution would run on Tab. Each value is escaped whole, since what needs
# escaping depends on where in the word a character sits. trim_word carries
# the current word escaped the same way, so that the trim the caller runs
# afterwards still recognizes its own prefix in the candidates.
# Args: current word, then every value.
_claude_reply_values() {
  local cur="$1" value
  shift
  COMPREPLY=()
  for value in "$@"; do
    if [[ "$value" == "$cur"* ]]; then
      printf -v value '%q' "$value"
      COMPREPLY+=("$value")
    fi
  done
  printf -v trim_word '%q' "$cur"
  _claude_keep_order
}

# Entry point. The completion itself runs in _claude_complete, which leaves
# its candidates in COMPREPLY and the word it matched them against in cur.
# Where it escaped those candidates, trim_word holds cur escaped to match.
_claude_bash_completion()
{
  local cur prev words cword trim_word
  COMPREPLY=()
  _claude_complete
  _claude_ltrim_colon "${trim_word-$cur}"
  return 0
}

_claude_complete()
{
  if declare -F _comp_initialize >/dev/null; then
    # bash-completion's parser understands quoting and redirections; the raw
    # arrays stand in where the package is not installed. _comp_initialize is
    # the 2.12 name for _init_completion, which now lives in a compat file
    # that not every distribution ships. Both take -n to hold a character back
    # from COMP_WORDBREAKS: without it a colon splits the word under the
    # cursor, which leaves cur holding a fragment and prev holding a colon
    # instead of the flag the value belongs to.
    _comp_initialize -n : || return 0
  elif declare -F _init_completion >/dev/null; then
    _init_completion -n : || return 0
  else
    _claude_word_list
  fi

  # Completion can start inside an opening quote, which bash keeps in the
  # current word. Slash command names hold nothing that needs quoting, so
  # dropping that quote is all it takes for them to match.
  case "$cur" in
    [\'\"]/*) cur="${cur:1}" ;;
  esac

  # A flag whose value is optional, followed by a word starting with a dash,
  # means the user moved on to the next flag rather than typing the value.
  case "$prev" in
    --cloud|-d|--debug|--from-pr|--prompt-suggestions|--remote-control|\
    -r|--resume|--teleport|--tmux|-w|--worktree)
      [[ "$cur" == -* ]] && prev=""
      ;;
  esac

  # A variadic flag governs every value word that follows it, not just the
  # first, so `--add-dir a b` keeps completing directories.
  local value_flag="$prev" i
  if [[ "$cur" != -* ]]; then
    for ((i = cword - 1; i > 0; i--)); do
      if [[ "${words[i]}" == -* ]]; then
        _claude_flag_in "${words[i]}" "${_CLAUDE_VARIADIC_FLAGS[@]}" && value_flag="${words[i]}"
        break
      fi
    done
  fi

  # Flag and slash command argument value completions
  case "$value_flag" in
    --model|--fallback-model|--judge-model|/model)
      mapfile -t COMPREPLY < <(compgen -W "default best sonnet opus haiku fable sonnet[1m] opus[1m] fable[1m] opusplan claude-fable-5-1 claude-fable-5-1[1m] claude-fable-5 claude-fable-5[1m] claude-opus-5 claude-opus-5[1m] claude-sonnet-5 claude-sonnet-5[1m] claude-opus-4-8 claude-opus-4-8[1m] claude-opus-4-7 claude-opus-4-7[1m] claude-opus-4-6 claude-opus-4-6[1m] claude-sonnet-4-6 claude-sonnet-4-6[1m] claude-haiku-4-5 claude-haiku-4-5-20251001" -- "$cur")
      return 0
      ;;
    --output-format)
      mapfile -t COMPREPLY < <(compgen -W "text json stream-json" -- "$cur")
      return 0
      ;;
    --input-format)
      mapfile -t COMPREPLY < <(compgen -W "text stream-json" -- "$cur")
      return 0
      ;;
    --permission-mode)
      mapfile -t COMPREPLY < <(compgen -W "default acceptEdits auto bypassPermissions manual dontAsk plan" -- "$cur")
      return 0
      ;;
    --prompt-suggestions)
      mapfile -t COMPREPLY < <(compgen -W "true false yes no on off 1 0" -- "$cur")
      return 0
      ;;
    --system-prompt-snapshot)
      mapfile -t COMPREPLY < <(compgen -W "on off" -- "$cur")
      return 0
      ;;
    --effort)
      _claude_reply_ordered "${_CLAUDE_EFFORT_LEVELS[*]}" "$cur"
      return 0
      ;;
    --autocompact)
      # Any token count from 100k to 1M is accepted, so these are round-number
      # hints next to the `auto` keyword rather than an exhaustive value list.
      _claude_reply_ordered "auto 100k 200k 500k 1m" "$cur"
      return 0
      ;;
    --tools|--allowedTools|--allowed-tools|--disallowedTools|--disallowed-tools)
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_TOOL_NAMES[*]}" -- "$cur")
      return 0
      ;;
    -r|--resume)
      # A transcript sits at ~/.claude/projects/<encoded cwd>/<session-id>.jsonl.
      # Every project directory is read for ids, not just the current one,
      # because resuming by id falls back to scanning all of them: a session
      # started elsewhere still resumes here. Titles lead (see
      # _claude_session_titles), a session being far easier to recognize by
      # the name it was given than by its id.
      # The word already typed narrows the glob, which spares ls a stat of
      # every transcript on the machine. Quoted, it matches literally, exactly
      # as the prefix match on the candidates does.
      local -a _claude_titles ids=()
      local listing
      _claude_session_titles
      listing=$(command ls -t "$HOME"/.claude/projects/*/"$cur"*.jsonl \
        2>/dev/null | sed 's|.*/||; s|\.jsonl$||')
      # mapfile reads a here-string in blocks; from a pipe it reads a byte at
      # a time, which costs more than everything else here put together.
      [[ -z "$listing" ]] || mapfile -t ids <<< "$listing"
      _claude_reply_values "$cur" "${_claude_titles[@]}" "${ids[@]}"
      return 0
      ;;
    /code-review)
      if [[ "$cur" == -* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_CODE_REVIEW_FLAGS[*]}" -- "$cur")
      else
        mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_CODE_REVIEW_ARGS[*]}" -- "$cur")
      fi
      return 0
      ;;
    /plugin)
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_PLUGIN_SUBCOMMANDS[*]}" -- "$cur")
      return 0
      ;;
    marketplace)
      # Only the marketplace sub-subcommand of /plugin; guard against the
      # standalone /marketplace builtin and unrelated contexts.
      if [[ " ${COMP_WORDS[*]} " == *" /plugin "* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_PLUGIN_MARKETPLACE_SUBCOMMANDS[*]}" -- "$cur")
        return 0
      fi
      ;;
    --setting-sources)
      mapfile -t COMPREPLY < <(compgen -W "user project local" -- "$cur")
      return 0
      ;;
    --mcp-config|--system-prompt-file|--append-system-prompt-file|--settings|--debug-file)
      _claude_filedir
      return 0
      ;;
    --plugin-dir|--add-dir|--cwd|--output-dir|--base-dir|--hooks-dir)
      _claude_filedir -d
      return 0
      ;;
  esac

  # Once a subcommand is named, its own flags, sub-subcommands, and values
  # replace the global lists.
  local _claude_word _claude_word_idx cmd="" cmd_idx=0 sub="" sub_idx=0 slash_cmd=""
  if _claude_find_word 1 "${words[@]:0:cword}"; then
    cmd="$_claude_word"
    cmd_idx="$_claude_word_idx"
  fi
  # A slash command occupies the same position but belongs to the block below,
  # and rules out a subcommand for the rest of the line.
  if [[ "$cmd" == /* ]]; then
    slash_cmd="$cmd"
    cmd=""
  fi

  if [[ -n "$cmd" ]]; then
    if _claude_find_word $((cmd_idx + 1)) "${words[@]:0:cword}"; then
      sub="$_claude_word"
      sub_idx="$_claude_word_idx"
    fi
    case "$cmd" in
      agents)
        _claude_reply_subcommand "$cur" "--add-dir --agent --all --allow-dangerously-skip-permissions --cwd --dangerously-skip-permissions --effort --json --mcp-config --model --permission-mode --plugin-dir --restricted --setting-sources --settings --strict-mcp-config -h --help"
        return 0
        ;;
      attach|logs|rm|stop)
        _claude_reply_subcommand "$cur" "-h --help"
        return 0
        ;;
      auth)
        case "$sub" in
          login) _claude_reply_subcommand "$cur" "--claudeai --console --email --sso -h --help" "" ;;
          status) _claude_reply_subcommand "$cur" "--json --text -h --help" "" ;;
          logout) _claude_reply_subcommand "$cur" "-h --help" "" ;;
          *) _claude_reply_subcommand "$cur" "-h --help" "${_CLAUDE_AUTH_SUBCOMMANDS[*]}" ;;
        esac
        return 0
        ;;
      auto-mode)
        case "$sub" in
          critique) _claude_reply_subcommand "$cur" "--model -h --help" "" ;;
          defaults) _claude_reply_subcommand "$cur" "--label -h --help" "" ;;
          reset) _claude_reply_subcommand "$cur" "-y --yes -h --help" "" ;;
          config) _claude_reply_subcommand "$cur" "-h --help" "" ;;
          *) _claude_reply_subcommand "$cur" "-h --help" "${_CLAUDE_AUTO_MODE_SUBCOMMANDS[*]}" ;;
        esac
        return 0
        ;;
      daemon)
        case "$sub" in
          stop) _claude_reply_subcommand "$cur" "--any --keep-workers -h --help" "" ;;
          logs|run|status|uninstall) _claude_reply_subcommand "$cur" "-h --help" "" ;;
          *) _claude_reply_subcommand "$cur" "--json-path --log-file -h --help" "${_CLAUDE_DAEMON_SUBCOMMANDS[*]}" ;;
        esac
        return 0
        ;;
      doctor|setup-token|update|upgrade)
        _claude_reply_subcommand "$cur" "-h --help"
        return 0
        ;;
      gateway)
        _claude_reply_subcommand "$cur" "--config -h --help"
        return 0
        ;;
      import)
        _claude_reply_subcommand "$cur" "--dry-run --yes -h --help" "codex gemini"
        return 0
        ;;
      install)
        _claude_reply_subcommand "$cur" "--force -h --help" "stable latest"
        return 0
        ;;
      mcp)
        case "$prev" in
          -s|--scope)
            mapfile -t COMPREPLY < <(compgen -W "local user project" -- "$cur")
            return 0
            ;;
          -t|--transport)
            mapfile -t COMPREPLY < <(compgen -W "stdio sse http" -- "$cur")
            return 0
            ;;
        esac
        case "$sub" in
          add) _claude_reply_subcommand "$cur" "--callback-port --client-id --client-secret -e --env -H --header -s --scope -t --transport -h --help" "" ;;
          add-json) _claude_reply_subcommand "$cur" "--client-secret -s --scope -h --help" "" ;;
          add-from-claude-desktop|remove) _claude_reply_subcommand "$cur" "-s --scope -h --help" "" ;;
          login) _claude_reply_subcommand "$cur" "--no-browser -h --help" "" ;;
          serve) _claude_reply_subcommand "$cur" "-d --debug --verbose -h --help" "" ;;
          get|list|logout|reset-project-choices) _claude_reply_subcommand "$cur" "-h --help" "" ;;
          *) _claude_reply_subcommand "$cur" "-h --help" "${_CLAUDE_MCP_SUBCOMMANDS[*]}" ;;
        esac
        return 0
        ;;
      plugin|plugins)
        local nested=""
        case "$prev" in
          -s|--scope)
            local scopes="user project local"
            # Only `update` accepts this scope; the others reject it.
            [[ "$sub" == "update" ]] && scopes+=" managed"
            mapfile -t COMPREPLY < <(compgen -W "$scopes" -- "$cur")
            return 0
            ;;
          --mocks)
            mapfile -t COMPREPLY < <(compgen -W "record off" -- "$cur")
            return 0
            ;;
        esac
        if [[ "$sub" == "marketplace" || "$sub" == "eval" ]]; then
          _claude_find_word $((sub_idx + 1)) "${words[@]:0:cword}" && nested="$_claude_word"
        fi
        case "$sub" in
          marketplace)
            case "$nested" in
              add) _claude_reply_subcommand "$cur" "--scope --sparse -h --help" "" ;;
              list) _claude_reply_subcommand "$cur" "--json -h --help" "" ;;
              remove|rm) _claude_reply_subcommand "$cur" "--scope -h --help" "" ;;
              update) _claude_reply_subcommand "$cur" "-h --help" "" ;;
              *) _claude_reply_subcommand "$cur" "-h --help" "${_CLAUDE_PLUGIN_CLI_MARKETPLACE_SUBCOMMANDS[*]}" ;;
            esac
            ;;
          eval)
            if [[ "$nested" == "init" ]]; then
              _claude_reply_subcommand "$cur" "--bare --eval-dir -i --interactive -h --help"
            else
              _claude_reply_subcommand "$cur" "--ablation --allow-tools --case --eval-dir --json --judge-model --keep-temp --max-cost-usd --mocks --model --no-publish --no-scaffold --output-dir --publish-report --report --runs --scaffold --tag --threshold --verbose -h --help" "init"
            fi
            ;;
          init|new) _claude_reply_subcommand "$cur" "--author --author-email --description -f --force --with -h --help" "" ;;
          install|i) _claude_reply_subcommand "$cur" "--config -s --scope -y --yes -h --help" "" ;;
          disable) _claude_reply_subcommand "$cur" "-a --all -s --scope -h --help" "" ;;
          enable) _claude_reply_subcommand "$cur" "-s --scope -h --help" "" ;;
          update) _claude_reply_subcommand "$cur" "-s --scope -y --yes -h --help" "" ;;
          list) _claude_reply_subcommand "$cur" "--available --json -h --help" "" ;;
          prune|autoremove) _claude_reply_subcommand "$cur" "--dry-run -s --scope -y --yes -h --help" "" ;;
          tag) _claude_reply_subcommand "$cur" "--dry-run -f --force -m --message --push --remote -h --help" "" ;;
          uninstall|remove) _claude_reply_subcommand "$cur" "--keep-data --prune -s --scope -y --yes -h --help" "" ;;
          validate) _claude_reply_subcommand "$cur" "--strict -h --help" "" ;;
          details) _claude_reply_subcommand "$cur" "-h --help" "" ;;
          *) _claude_reply_subcommand "$cur" "-h --help" "${_CLAUDE_PLUGIN_CLI_SUBCOMMANDS[*]}" ;;
        esac
        return 0
        ;;
      project)
        case "$sub" in
          purge) _claude_reply_subcommand "$cur" "--all --dry-run -i --interactive -y --yes -h --help" "" ;;
          *) _claude_reply_subcommand "$cur" "-h --help" "${_CLAUDE_PROJECT_SUBCOMMANDS[*]}" ;;
        esac
        return 0
        ;;
      rc|remote-control)
        case "$prev" in
          --spawn)
            mapfile -t COMPREPLY < <(compgen -W "same-dir worktree session" -- "$cur")
            return 0
            ;;
        esac
        _claude_reply_subcommand "$cur" "--capacity -c --continue --create-session-in-dir --debug-file --name --no-create-session-in-dir --permission-mode --remote-control-session-name-prefix --session-id --spawn -v --verbose -h --help"
        return 0
        ;;
      respawn)
        _claude_reply_subcommand "$cur" "--all -h --help"
        return 0
        ;;
      self-hosted-runner)
        _claude_reply_subcommand "$cur" "--api-url --base-dir --capacity --client-label --configure-git --confine-repo-settings --debug-token-dir --defer-shutdown-max-min --drain-grace-sec --drain-wait-sec --environment-secret-file --exec-path --exit-if-unused-min --git-host-rewrite --git-ssh-rewrite --health-port --hooks-dir --kill-session-after-min --lock-to-account --log-file --log-level --post-session-hook-timeout-sec --proxy-authorization-command --proxy-authorization-file --push-outcome-on-release --release-idle-session-min --retire-at --session-stop-grace-sec --startup-timeout-min --trust-workspace --use-anthropic-git-proxy -h --help"
        return 0
        ;;
      ultrareview)
        _claude_reply_subcommand "$cur" "--json --no-post --post --timeout -h --help"
        return 0
        ;;
    esac
  fi

  # Flag completions
  if [[ "$cur" == -* ]]; then
    if [[ " ${COMP_WORDS[*]} " == *" /code-review "* ]]; then
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_CODE_REVIEW_FLAGS[*]}" -- "$cur")
    else
      mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_FLAGS[*]}" -- "$cur")
    fi
    return 0
  fi

  # Subcommand completions, until a subcommand or slash command has been named
  if [[ -z "$cmd" && -z "$slash_cmd" && "$cur" != /* && "$cur" != -* ]]; then
    mapfile -t COMPREPLY < <(compgen -W "${_CLAUDE_SUBCOMMANDS[*]}" -- "$cur")
    return 0
  fi

  if [[ "$cur" == /* ]]; then
    local commands_dir="$HOME/.claude/commands"
    local skills_dir="$HOME/.claude/skills"
    local project_root project_commands_dir project_skills_dir
    local custom_commands="" personal_skills="" project_commands="" project_skills=""

    # Detect project root via git. Every way git can fail means the same thing
    # here as "not in a repository", including git not being installed at all,
    # so keep its exit status from escaping the assignment.
    project_root=$(git rev-parse --show-toplevel 2>/dev/null) || project_root=""

    custom_commands=$(_claude_discover_commands "$commands_dir" "*.md" ".md")
    personal_skills=$(_claude_discover_commands "$skills_dir" "SKILL.md" "/SKILL.md")

    # Project-level commands and skills (if inside a git repo)
    if [[ -n "$project_root" ]]; then
      project_commands_dir="$project_root/.claude/commands"
      project_skills_dir="$project_root/.claude/skills"

      project_commands=$(_claude_discover_commands "$project_commands_dir" "*.md" ".md")
      project_skills=$(_claude_discover_commands "$project_skills_dir" "SKILL.md" "/SKILL.md")
    fi

    # Combine all sources and deduplicate
    local all_commands
    all_commands=$(printf '%s\n' "${_CLAUDE_BUILTIN_COMMANDS[@]}" "$custom_commands" "$personal_skills" "$project_commands" "$project_skills" | sort -u)

    mapfile -t COMPREPLY < <(compgen -W "$all_commands" -- "${cur}")
  fi

  return 0
}
complete -o default -F _claude_bash_completion claude
