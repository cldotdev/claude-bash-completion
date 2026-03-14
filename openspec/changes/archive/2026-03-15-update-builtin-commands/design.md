## Context

The `claude-completion.bash` script provides tab completion for Claude Code CLI slash commands. The `builtin_commands` array was last updated for v2.1.71 (77 commands). Claude Code is now at v2.1.76 with 3 new commands and 1 removed command — totaling 79 completable commands (63 built-in + 5 bundled skills + 11 aliases).

## Goals / Non-Goals

**Goals:**

- Update `builtin_commands` array to match Claude Code v2.1.76
- Remove `/output-style` (no longer a standalone command)
- Add `/btw`, `/color`, `/effort`
- Update documentation (version comment, README command count)

**Non-Goals:**

- Change completion logic or behavior
- Add new features to the completion script
- Modify the wrapper function or discovery mechanism

## Decisions

### Remove /output-style

The `/output-style` command no longer appears in the official docs. Its functionality is now accessible through `/config`. Keeping it would complete a command that no longer exists.

### Source of truth

Use the official documentation at `docs.anthropic.com/en/docs/claude-code/commands` as the authoritative source for the command list. Cross-reference with bundled skills from the skills documentation page.

### Diff-based update procedure

Document a reproducible procedure (curl + grep + comm) to diff the script against docs. This is captured in the plan file for future updates.

## Risks / Trade-offs

- [Commands may change between minor versions] -> Pin to v2.1.76 in the comment; updating is a mechanical process documented in the plan
- [Removing /output-style could break muscle memory] -> The command is no longer functional in Claude Code; completing it would be misleading
