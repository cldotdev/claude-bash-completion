# CLAUDE.md

## Update Procedure

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
