# CLAUDE.md

## Update Procedure

How to update the `builtin_commands` array when a new Claude Code version is released.

### Source of Truth

- Built-in commands: https://docs.anthropic.com/en/docs/claude-code/commands
- Bundled skills: https://docs.anthropic.com/en/docs/claude-code/skills#bundled-skills

### Check Current Version

```bash
claude --version
```

Compare with the version in `claude-completion.bash` comment (line starting with `# Built-in slash commands`).

### Diff Against Docs

```bash
./scripts/diff-commands.sh
```

The script fetches the latest commands and bundled skills from the official docs, compares them against `builtin_commands` in `claude-completion.bash`, and prints new/removed commands.

### Cross-reference Aliases

The docs page lists aliases inline (e.g., "Aliases: `/reset`, `/new`"). Verify aliases are included in the script output.

### Apply Changes

- Add new commands to `builtin_commands` array in alphabetical order.
- Update the version comment: count and version number.
- Update `README.md` with the new count and version.

### Verify

- `shellcheck claude-completion.bash` — no warnings.
- Count commands matches the comment: `sed -n '/builtin_commands=(/,/)/p' claude-completion.bash | grep -oP '/[a-z][-a-z]*' | wc -l`
- Source the script and confirm `complete -p claude` registers the function.

### Notes

- The docs commands page includes both built-in commands and some bundled skills in its table. The skills page has the authoritative bundled skills list.
- Aliases (e.g., `/bug` for `/feedback`) are listed in the command table and should be included for discoverability.
- Some commands are platform/plan-specific (e.g., `/desktop`, `/upgrade`). Include all for universal completion.
