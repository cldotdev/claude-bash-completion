# ========================================
# Claude Bash Completion
# ========================================

# Prevent warnings about readonly variables littering terminal if double-
# sourced, e.g. loaded via /etc/bash_completion.d and shell spawned in tmux.
[[ -z ${_CLAUDE_COMPLETION_LOADED:-} ]] || return 0 2>/dev/null || exit 0
_CLAUDE_COMPLETION_LOADED=Y

# Wrapper function to merge slash command arguments into a single parameter
# This allows slash commands to receive multi-word arguments properly.
# Example: `claude --model haiku /format 'some text'` becomes
#          `claude --model haiku "/format some text"`
claude() {
  local args_before=()
  local slash_cmd_with_rest=""
  local found_slash=""

  for arg in "$@"; do
    if [[ -z "$found_slash" && "$arg" == /* ]]; then
      found_slash=1
      slash_cmd_with_rest="$arg"
    elif [[ -n "$found_slash" ]]; then
      slash_cmd_with_rest="$slash_cmd_with_rest $arg"
    else
      args_before+=("$arg")
    fi
  done

  if [[ -n "$found_slash" ]]; then
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
# Returns an empty string if no frontmatter or no name field found.
_claude_frontmatter_name() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -n '
    1{
      /^---$/!q
    }
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
# Args: base_dir find_pattern strip_suffix
_claude_discover_commands() {
  local base_dir="$1" find_pattern="$2" strip_suffix="$3"
  find -L "$base_dir" -type f -name "$find_pattern" 2>/dev/null | while read -r file; do
    local name
    name=$(_claude_frontmatter_name "$file")
    if [[ -n "$name" ]]; then
      echo "/$name"
    else
      local rel="${file#"$base_dir"/}"
      rel="${rel%"$strip_suffix"}"
      rel="${rel//\//:}"
      echo "/$rel"
    fi
  done
}

# Built-in slash commands (125 commands as of v2.1.241)
_CLAUDE_BUILTIN_COMMANDS=(
  /add-dir /advisor /allowed-tools /android /app
  /artifact-capabilities /artifact-design /artifact-diagramming /artifacts
  /autocompact /autofix-pr
  /background /bashes /batch /bg /branch /brief /btw /bug
  /cd /checkpoint /checkup /chrome /claude-api /claude-in-chrome /clear /code-review /color
  /compact /config /context /continue /copy /cost
  /dataviz /debug /deep-research /design /design-login /design-sync /desktop /diff /doctor
  /effort /exit /export
  /fast /feedback /fewer-permission-prompts /focus /fork
  /goal
  /help /hooks
  /ide /init /insights /install-github-app /install-slack-app /ios
  /keybindings /keybindings-help
  /login /logout /loop
  /marketplace /mcp /memory /mobile /model /name /new
  /passes /permissions /plan /plugin /plugins /powerup
  /privacy-settings /proactive /quit
  /rc /recap /release-notes /reload-plugins /reload-skills /remote-control
  /remote-env /rename /reset /resume /review /rewind /routines /run /run-skill-generator
  /sandbox /schedule /scroll-speed /security-review /settings /share
  /simplify /skills /stats /status /statusline /stickers /subtask
  /tasks /team-onboarding /teleport /terminal-setup /theme /tp /tui
  /ultrareview /undo /update-config /upgrade /usage /usage-credits
  /verify /voice /workflows
)
readonly -a _CLAUDE_BUILTIN_COMMANDS

# CLI flags (75 flags as of v2.1.241)
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
  -r --resume
  --safe-mode
  --session-id --setting-sources --settings --strict-mcp-config
  --system-prompt --system-prompt-file
  --teleport --tmux --tools
  --verbose
  -v --version
  -w --worktree
)
readonly -a _CLAUDE_FLAGS

# CLI subcommands (24 subcommands as of v2.1.241)
_CLAUDE_SUBCOMMANDS=(
  agents attach auth auto-mode daemon doctor gateway import install
  logs mcp plugin plugins project rc remote-control respawn rm
  self-hosted-runner setup-token stop ultrareview update upgrade
)
readonly -a _CLAUDE_SUBCOMMANDS

# Effort levels (shared by --effort flag and /code-review command)
_CLAUDE_EFFORT_LEVELS=(low medium high xhigh max)
readonly -a _CLAUDE_EFFORT_LEVELS

# Flags accepted by the /code-review command (shared by both flag paths)
_CLAUDE_CODE_REVIEW_FLAGS=(--comment --fix)
readonly -a _CLAUDE_CODE_REVIEW_FLAGS

# Positional values accepted by the /code-review command: the effort levels
# plus "ultra", which escalates the review to the cloud-hosted /ultrareview
_CLAUDE_CODE_REVIEW_ARGS=("${_CLAUDE_EFFORT_LEVELS[@]}" ultra)
readonly -a _CLAUDE_CODE_REVIEW_ARGS

# Subcommands accepted by the /plugin command
_CLAUDE_PLUGIN_SUBCOMMANDS=(install uninstall enable disable list marketplace)
readonly -a _CLAUDE_PLUGIN_SUBCOMMANDS

# Sub-subcommands accepted by /plugin marketplace
_CLAUDE_PLUGIN_MARKETPLACE_SUBCOMMANDS=(add remove list update)
readonly -a _CLAUDE_PLUGIN_MARKETPLACE_SUBCOMMANDS

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
  --system-prompt --system-prompt-file --teleport --tmux --tools
  -w --worktree
)
readonly -a _CLAUDE_VALUE_FLAGS

# Flags that take several space-separated values. Every one of those words
# belongs to the flag, so the flag governs completion until the next one appears.
_CLAUDE_VARIADIC_FLAGS=(
  --add-dir --allowedTools --allowed-tools --betas
  --disallowedTools --disallowed-tools --file --tools
)
readonly -a _CLAUDE_VARIADIC_FLAGS

# Built-in tool names accepted by --tools, --allowedTools, and --disallowedTools.
# `claude --help` carries no listing and the CLI accepts unknown names without
# complaint, so this mirrors the built-in section of the tool ordering table in
# the v2.1.241 binary. MCP and self-hosted-runner tools are left out: those
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
readonly -a _CLAUDE_TOOL_NAMES

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
readonly -a _CLAUDE_AUTH_SUBCOMMANDS _CLAUDE_AUTO_MODE_SUBCOMMANDS
readonly -a _CLAUDE_DAEMON_SUBCOMMANDS _CLAUDE_MCP_SUBCOMMANDS
readonly -a _CLAUDE_PLUGIN_CLI_SUBCOMMANDS
readonly -a _CLAUDE_PLUGIN_CLI_MARKETPLACE_SUBCOMMANDS _CLAUDE_PROJECT_SUBCOMMANDS

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

# Complete paths through bash-completion's _filedir, which escapes spaces and
# other metacharacters, falling back to compgen where it is not loaded.
_claude_filedir() {
  if declare -F _filedir >/dev/null; then
    _filedir "$@"
  elif [[ "${1-}" == "-d" ]]; then
    mapfile -t COMPREPLY < <(compgen -d -- "${COMP_WORDS[COMP_CWORD]}")
  else
    mapfile -t COMPREPLY < <(compgen -f -- "${COMP_WORDS[COMP_CWORD]}")
  fi
}

# Offer a word list, keeping the order it is written in, so ordered lists such
# as effort levels do not come back alphabetized.
# Args: word list, current word.
_claude_reply_ordered() {
  mapfile -t COMPREPLY < <(compgen -W "$1" -- "$2")
  # compopt fails when called outside a completion; the ordering is a nicety,
  # not a reason to hand the caller a failure.
  compopt -o nosort 2>/dev/null || true
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

_claude_bash_completion()
{
  local cur prev words cword
  COMPREPLY=()
  if declare -F _init_completion >/dev/null; then
    # bash-completion's parser understands quoting and redirections; the raw
    # arrays stand in where the package is not installed.
    _init_completion || return 0
  else
    words=("${COMP_WORDS[@]}")
    cword="$COMP_CWORD"
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
  fi

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
      mapfile -t COMPREPLY < <(compgen -W "default best sonnet opus haiku fable sonnet[1m] opus[1m] fable[1m] opusplan claude-fable-5 claude-fable-5[1m] claude-opus-5 claude-opus-5[1m] claude-sonnet-5 claude-sonnet-5[1m] claude-opus-4-8 claude-opus-4-8[1m] claude-opus-4-7 claude-opus-4-7[1m] claude-opus-4-6 claude-opus-4-6[1m] claude-sonnet-4-6 claude-sonnet-4-6[1m] claude-haiku-4-5 claude-haiku-4-5-20251001" -- "$cur")
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
      # A transcript sits at ~/.claude/projects/<cwd, slashes turned into
      # dashes>/<session-id>.jsonl. Every project directory is read, not just
      # the current one, because resuming by ID falls back to scanning all of
      # them: a session started elsewhere still resumes here.
      _claude_reply_ordered "$(command ls -t "$HOME"/.claude/projects/*/*.jsonl \
        2>/dev/null | sed 's|.*/||; s|\.jsonl$||')" "$cur"
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
        _claude_reply_subcommand "$cur" "--add-dir --agent --all --allow-dangerously-skip-permissions --cwd --dangerously-skip-permissions --effort --json --mcp-config --model --permission-mode --plugin-dir --setting-sources --settings --strict-mcp-config -h --help"
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
              _claude_reply_subcommand "$cur" "--ablation --allow-tools --case --eval-dir --json --judge-model --keep-temp --max-cost-usd --model --no-publish --no-scaffold --output-dir --publish-report --report --runs --scaffold --tag --threshold --verbose -h --help" "init"
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
        _claude_reply_subcommand "$cur" "--api-url --base-dir --capacity --configure-git --confine-repo-settings --debug-token-dir --defer-shutdown-max-min --drain-grace-sec --drain-wait-sec --environment-secret-file --exec-path --exit-if-unused-min --git-host-rewrite --git-ssh-rewrite --health-port --hooks-dir --kill-session-after-min --lock-to-account --log-file --log-level --post-session-hook-timeout-sec --proxy-authorization-command --proxy-authorization-file --push-outcome-on-release --release-idle-session-min --retire-at --session-stop-grace-sec --startup-timeout-min --trust-workspace --use-anthropic-git-proxy -h --help"
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

    # Detect project root via git
    project_root=$(git rev-parse --show-toplevel 2>/dev/null)

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
