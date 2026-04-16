# AGENTS.md

## Built-in Command Update Procedure

How to update the `_CLAUDE_BUILTIN_COMMANDS` array when a new Claude Code version is released.

### Source of Truth

- [Claude Code changelog](https://raw.githubusercontent.com/anthropics/claude-code/refs/heads/main/CHANGELOG.md)
- Baseline established at v2.1.92 by auditing the installed binary and cross-referencing with the changelog

### Update Steps

1. Read the changelog for the target version.
2. Identify slash command additions and removals (new commands, removed commands, renamed commands, new bundled skills).
3. Update `_CLAUDE_BUILTIN_COMMANDS` array in `claude-completion.bash`:
   - Add new commands in alphabetical order.
   - Remove commands no longer present.
   - Update the version comment: count and version number.
4. Update `README.md` with the new count and version.

### Verify

- `shellcheck claude-completion.bash` -- no warnings.
- Command count matches the comment: `sed -n '/_CLAUDE_BUILTIN_COMMANDS=(/,/)/p' claude-completion.bash | grep -oP '/[a-z][-a-z]*' | wc -l`
- Source the script and confirm `complete -p claude` registers the function.

### Notes

- Plugins (`~/.claude/plugins/`) and user-installed skills (`~/.claude/skills/`) are not built-in; they are handled by dynamic discovery at tab-completion time.

## Model Update Procedure

How to update the `--model` and `--fallback-model` value completions when Anthropic releases a new model or retires an existing one.

### Source of Truth

- [Claude API models overview](https://platform.claude.com/docs/en/about-claude/models/overview)

### Update Steps

1. Fetch the Claude API models overview page.
2. Identify model changes:
   - New current-generation models (add API ID and alias).
   - Newly deprecated models with a retirement date within the next 6 months (drop them).
   - Aliases added or removed for existing snapshot IDs.
3. Update the `compgen -W` list for `--model` and `--fallback-model` in `claude-completion.bash`. Keep:
   - Claude Code aliases: `default`, `best`, `sonnet`, `opus`, `haiku`, `sonnet[1m]`, `opus[1m]`, `opusplan`.
   - All current model API IDs and their aliases.
   - Legacy models still actively used by Claude Code (e.g., `claude-opus-4-6` for `/fast` mode).
4. Skip deprecated models that will be retired within 6 months to avoid steering users to expiring IDs.

### Verify

- `bats tests/completion.bats` -- all tests pass.
- `bash -c 'source claude-completion.bash; COMP_WORDS=(claude --model ""); COMP_CWORD=2; COMPREPLY=(); _claude_bash_completion; printf "%s\n" "${COMPREPLY[@]}"'` lists the expected model IDs.
