# CLAUDE.md

## Update Procedure

How to update the `builtin_commands` array when a new Claude Code version is released.

### Source of Truth

- Installed Claude binary (sole source)
- The binary is a Bun-compiled executable with embedded JS; each built-in command is defined with `type:"local"/"local-jsx"/"prompt"` fields or registered via `e3()`/`oZ7()` calls

### Check Current Version

```bash
claude --version
```

Compare with the version in `claude-completion.bash` comment (line starting with `# Built-in slash commands`).

### Diff

```bash
./scripts/diff-commands.sh
```

The script extracts command definitions from the installed Claude binary using structured type patterns, compares them against `builtin_commands` in `claude-completion.bash`, and prints new/removed commands. It automatically handles aliases and excludes hidden/internal commands.

### Apply Changes

- Add new commands to `builtin_commands` array in alphabetical order.
- Remove commands no longer in the binary.
- Update the version comment: count and version number.
- Update `README.md` with the new count and version.

### Verify

- `shellcheck claude-completion.bash` -- no warnings.
- Command count matches the comment: `sed -n '/builtin_commands=(/,/)/p' claude-completion.bash | grep -oP '/[a-z][-a-z]*' | wc -l`
- Source the script and confirm `complete -p claude` registers the function.

### Notes

- The binary extraction pattern depends on the Bun-compiled JS structure. If Claude Code changes its bundling, the regex in `diff-commands.sh` may need adjustment -- this would be evident from anomalous output (zero commands or unexpected names).
- Aliases (e.g., `/reset` for `/clear`) are extracted automatically from `aliases:[...]` fields.
- Commands with `isHidden` or disabled `isEnabled` are excluded.
- Plugins (`~/.claude/plugins/`) and user-installed skills (`~/.claude/skills/`) are not built-in; they are handled by dynamic discovery at tab-completion time.
