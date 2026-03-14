# Update Procedure

How to update the `builtin_commands` array when a new Claude Code version is released.

## Source of Truth

- Built-in commands: https://docs.anthropic.com/en/docs/claude-code/commands
- Bundled skills: https://docs.anthropic.com/en/docs/claude-code/skills#bundled-skills

## Check Current Version

```bash
claude --version
```

Compare with the version in `claude-completion.bash` comment (line starting with `# Built-in slash commands`).

## Extract Current Commands

```bash
sed -n '/builtin_commands=(/,/)/p' claude-completion.bash \
  | grep -oP '/[a-z][-a-z]*' | sort -u > /tmp/current_commands.txt
```

## Fetch Latest Built-in Commands

```bash
curl -sL https://docs.anthropic.com/en/docs/claude-code/commands \
  | grep -oP '(?<=<code>)/[a-z][-a-z]*(?=[\s<])' \
  | sort -u > /tmp/docs_commands.txt
```

## Fetch Latest Bundled Skills

```bash
curl -sL https://docs.anthropic.com/en/docs/claude-code/skills \
  | sed -n '/<table/,/<\/table>/p' | head -1 \
  | grep -oP '(?<=<code>)/[a-z][-a-z]*(?=[\s<])' \
  | sort -u > /tmp/docs_skills.txt
```

## Diff

```bash
cat /tmp/docs_commands.txt /tmp/docs_skills.txt | sort -u > /tmp/docs_all.txt

# New commands (in docs but not in script):
comm -23 /tmp/docs_all.txt /tmp/current_commands.txt

# Removed commands (in script but not in docs):
comm -13 /tmp/docs_all.txt /tmp/current_commands.txt
```

## Cross-reference Aliases

The docs page lists aliases inline (e.g., "Aliases: `/reset`, `/new`"). Verify aliases are included in the commands table output. Also check for commands marked "Deprecated" and decide whether to keep or remove them.

## Apply Changes

- Add new commands to `builtin_commands` array in alphabetical order.
- Remove obsolete commands.
- Update the version comment: count and version number.
- Update `README.md` with the new count and version.

## Verify

- `shellcheck claude-completion.bash` — no warnings.
- Count commands matches the comment: `sed -n '/builtin_commands=(/,/)/p' claude-completion.bash | grep -oP '/[a-z][-a-z]*' | wc -l`
- Source the script and confirm `complete -p claude` registers the function.

## Notes

- The docs commands page includes both built-in commands and some bundled skills in its table. The skills page has the authoritative bundled skills list.
- Aliases (e.g., `/bug` for `/feedback`) are listed in the command table and should be included for discoverability.
- Some commands are platform/plan-specific (e.g., `/desktop`, `/upgrade`). Include all for universal completion.
