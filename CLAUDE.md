# Project Instructions

## Completion Alignment Procedure

How to update the `_CLAUDE_BUILTIN_COMMANDS`, `_CLAUDE_FLAGS`, and `_CLAUDE_SUBCOMMANDS` arrays, the per-subcommand trees, and the flag value completions when a new Claude Code version is released.

### Source of Truth

- [Claude Code changelog](https://raw.githubusercontent.com/anthropics/claude-code/refs/heads/main/CHANGELOG.md)
- TUI slash menu audit of the installed binary as a supplement; the changelog does not announce every command (the 12 commands added in the v2.1.211 alignment were found this way)
- `claude <subcommand> --help` for the per-subcommand trees and their flags, which the changelog rarely mentions; walk every subcommand that has sub-subcommands (`auth`, `auto-mode`, `daemon`, `mcp`, `plugin`, `plugin marketplace`, `plugin eval`, `project`)
- Baseline established at v2.1.92 by auditing the installed binary and cross-referencing with the changelog

### Update Steps

1. Read the changelog for the target version.
2. Identify additions and removals across slash commands (new, removed, and renamed commands; new bundled skills), CLI flags, CLI subcommands, sub-subcommands and their flags, and flag values (e.g., new `--permission-mode` values).
3. Update the affected lists in `claude-completion.bash` (`_CLAUDE_BUILTIN_COMMANDS`, `_CLAUDE_FLAGS`, `_CLAUDE_SUBCOMMANDS`, the per-subcommand arrays and the flag lists inside the `case "$cmd"` dispatch, and the `compgen -W` value lists):
   - Add new entries in alphabetical order.
   - Remove entries no longer present.
   - Update the version comments: count and version number.
4. Update `tests/completion.bats`: add tests for new entries and bump the count assertions.
5. Update `README.md` with the new counts and version.

### Verify

- `shellcheck claude-completion.bash` -- no warnings.
- `bats tests/` -- all tests pass. Run it again with `BASH_COMPLETION_LIB` pointed at an installed `bash_completion`, and a third time with `BASH_COMPLETION_DROP_DEPRECATED=1` alongside it, to cover the package path and the post-2.12 interface. CI runs all three.
- Command count matches the comment: `sed -n '/_CLAUDE_BUILTIN_COMMANDS=(/,/)/p' claude-completion.bash | grep -oE '/[a-z][-a-z]*' | wc -l`
- Source the script and confirm `complete -p claude` registers the function.

### Notes

- The lists cover what a default account can actually run, not just what `claude --help` prints. Include command aliases (`/tp` for `/teleport`, `/peers` for `/list-agents`, `rc` for `remote-control`) and hidden entries the product still documents in its own usage text (`claude attach|logs|stop|rm|respawn|daemon`, `claude self-hosted-runner`). Leave out undocumented internal aliases (`claude kill`, `claude sync`) and flags that only exist for subprocess plumbing (`--bg-pty-host`, `--preload`).
- Leave out commands a default account cannot invoke, and check this in the binary rather than assuming it: `strings` the installed build, find the command's object literal, and read its `isEnabled`. A statsig lookup that defaults off (`x("tengu_import", !1)` for `/import`) or a hardcoded `return !1` (`/loops`, and the helper behind `/desktop` and its `/app` alias, which the public build compiles to `!1`; checked in v2.1.247, v2.1.252, and v2.1.258) disqualifies the command. Gating on login state, org policy, platform, or terminal capability does not, because commands gated that way still run for some users. `/web-setup` reads an org policy that defaults to allowed, and `/setup-bedrock` is hidden only when `CLAUDE_CODE_USE_BEDROCK` is unset; both belong in the list. A gate can also be lifted, so re-read the ones a release touches: `/radio` lost its statsig gate in v2.1.251.
- Some commands are gated outside their own object by the `open()` predicate of the runtime gate map that `getRuntimeGatedBuiltinCommands` builds; `/skill-doctor` is gated there rather than in its own definition.
- A bundled skill marked `userInvocable:!1` (`/artifact-design`, which v2.1.252 still advertised, and `/keybindings-help`) is dropped from the slash menu and the `-p` init message, but `findCommand` matches on name alone, so typing it still runs it. Keep such entries in the list.
- A `local` command can be probed without spending tokens: `ANTHROPIC_API_KEY=sk-ant-dummy claude --bare -p /name` prints `Unknown command` for a name the registry does not hold (`/install`, `/version`), `isn't available in this environment` for one whose gate or availability check fails (`/desktop`), and the command's own output for one that runs (`/list-agents`). Prompt-type skills reach for the API instead, so the probe says nothing about them.
- User-installed skills (`~/.claude/skills/`) and custom commands (`~/.claude/commands/`) are not built-in; they are handled by dynamic discovery at tab-completion time, alongside their project-level counterparts.
- Commands and skills that a plugin (`~/.claude/plugins/`) brings in are out of scope for both lists. Which ones are active in a given directory follows from the install scope recorded in `installed_plugins.json` and from the `enabledPlugins` settings in effect there, and completion can read back neither dependably. Offering an entry the CLI would refuse costs more than omitting it, so leave those entries out.
- `--resume` completion reads two formats out of the binary rather than out of the docs, so re-check both when a release changes how transcripts are stored. The working directory is turned into a project directory name by `path.replace(/[^a-zA-Z0-9]/g, "-")`, truncated to 200 characters with a base36 hash of the path appended past that. A title is resolved by lowercasing and trimming both sides and comparing in full against `customTitle ?? aiTitle`, over the sessions of the working directory and the git worktrees it resolves to; one match resumes outright, anything else opens the picker with the string as a search term. Only `customTitle` is offered: `aiTitle` is auto-generated, collides often, and would bury the titles a user chose.
- `/agents` is intentionally excluded: its interactive wizard was removed in favor of `.claude/agents/` in v2.1.198, and its TUI menu entry is a tombstone marked "(removed)".

## Model Update Procedure

How to update the `--model` and `--fallback-model` value completions when Anthropic releases a new model or retires an existing one.

### Source of Truth

- [Claude API models overview](https://platform.claude.com/docs/en/about-claude/models/overview) -- current models, API IDs, and aliases
- [Model status table](https://platform.claude.com/docs/en/about-claude/model-deprecations#model-status) -- lifecycle state (Active, Legacy, Deprecated, Retired), deprecation dates, and retirement dates

### Update Steps

1. Fetch both pages above.
2. Identify model changes:
   - New current-generation models (add API ID and alias).
   - Models whose status moved off Active in the model status table (drop them per step 4).
   - Aliases added or removed for existing snapshot IDs.
3. Update the `compgen -W` list for `--model` and `--fallback-model` in `claude-completion.bash`. Keep:
   - Claude Code aliases: `default`, `best`, `sonnet`, `opus`, `haiku`, `fable`, `sonnet[1m]`, `opus[1m]`, `fable[1m]`, `opusplan`.
   - All current model API IDs and their aliases.
   - Older models still actively used by Claude Code (e.g., `claude-opus-4-7` for `/fast` mode).
4. Drop entries by lifecycle state, checking every model ID already in the list, not just the ones the release touched:
   - Retired: remove immediately, because requests to these models fail.
   - Deprecated: remove once the retirement date falls within 6 months, to avoid steering users to expiring IDs.
   - Legacy: keep while Claude Code still accepts the model, and re-check on the next update.

### Verify

- `bats tests/completion.bats` -- all tests pass.
- `bash -c 'source claude-completion.bash; COMP_WORDS=(claude --model ""); COMP_CWORD=2; COMPREPLY=(); _claude_bash_completion; printf "%s\n" "${COMPREPLY[@]}"'` lists the expected model IDs.
