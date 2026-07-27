# Project Instructions

## Completion Alignment Procedure

How to update the `_CLAUDE_BUILTIN_COMMANDS`, `_CLAUDE_FLAGS`, and `_CLAUDE_SUBCOMMANDS` arrays and the flag value completions when a new Claude Code version is released.

### Source of Truth

- [Claude Code changelog](https://raw.githubusercontent.com/anthropics/claude-code/refs/heads/main/CHANGELOG.md)
- TUI slash menu audit of the installed binary as a supplement; the changelog does not announce every command (the 12 commands added in the v2.1.211 alignment were found this way)
- Baseline established at v2.1.92 by auditing the installed binary and cross-referencing with the changelog

### Update Steps

1. Read the changelog for the target version.
2. Identify additions and removals across slash commands (new, removed, and renamed commands; new bundled skills), CLI flags, CLI subcommands, and flag values (e.g., new `--permission-mode` values).
3. Update the affected lists in `claude-completion.bash` (`_CLAUDE_BUILTIN_COMMANDS`, `_CLAUDE_FLAGS`, `_CLAUDE_SUBCOMMANDS`, and the `compgen -W` value lists):
   - Add new entries in alphabetical order.
   - Remove entries no longer present.
   - Update the version comments: count and version number.
4. Update `tests/completion.bats`: add tests for new entries and bump the count assertions.
5. Update `README.md` with the new counts and version.

### Verify

- `shellcheck claude-completion.bash` -- no warnings.
- `bats tests/` -- all tests pass.
- Command count matches the comment: `sed -n '/_CLAUDE_BUILTIN_COMMANDS=(/,/)/p' claude-completion.bash | grep -oP '/[a-z][-a-z]*' | wc -l`
- Source the script and confirm `complete -p claude` registers the function.

### Notes

- The lists cover everything the CLI accepts, not just what `claude --help` prints. Include command aliases (`/tp` for `/teleport`, `rc` for `remote-control`) and hidden entries the product still documents in its own usage text (`--teleport`, `claude attach|logs|stop|rm|respawn|daemon`). Leave out undocumented internal aliases (`claude kill`, `claude sync`) and flags that only exist for subprocess plumbing (`--bg-pty-host`, `--preload`).
- Plugins (`~/.claude/plugins/`) and user-installed skills (`~/.claude/skills/`) are not built-in; they are handled by dynamic discovery at tab-completion time.
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
