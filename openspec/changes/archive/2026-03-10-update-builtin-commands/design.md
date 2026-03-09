## Context

The `claude-completion.bash` script provides tab completion for Claude Code CLI slash commands. The `builtin_commands` array was last updated for v2.1.63 (55 commands). Claude Code is now at v2.1.71 with 57 built-in commands, 5 bundled skills, and 12 aliases - totaling 74 completable commands.

## Goals / Non-Goals

**Goals:**

- Update `builtin_commands` array to match Claude Code v2.1.71
- Include built-in commands, bundled skills, and aliases for complete tab-completion coverage
- Update documentation (version comment, README command count)

**Non-Goals:**

- Change completion logic or behavior
- Add new features to the completion script
- Modify the wrapper function or discovery mechanism

## Decisions

### Include aliases in the command list

Include command aliases (e.g., `/bug`, `/quit`, `/reset`) alongside main commands. Users may know either form, and tab completion should work for both. The official docs list these aliases, and Claude Code accepts them.

Alternative considered: Only include main command names. Rejected because users who know `/bug` would lose tab completion when it was renamed to an alias of `/feedback`.

### Alphabetical ordering within grouped lines

Maintain the existing convention: commands sorted alphabetically, grouped into lines of ~10 commands for readability. This matches all previous updates.

### Source of truth

Use the official documentation at `code.claude.com/docs/en/interactive-mode` as the authoritative source for the command list. Cross-reference with bundled skills from the skills documentation page.

## Risks / Trade-offs

- [Commands may change between minor versions] -> Pin to v2.1.71 in the comment; updating is a mechanical process documented in git history
- [Including aliases increases array size] -> Minimal impact; 74 entries vs 55 is negligible for completion performance
- [Some commands are platform/plan-specific] -> Include all for universal completion; non-applicable commands simply won't do anything if invoked
