## Why

The built-in commands list in `claude-completion.bash` is outdated (v2.1.63, 55 commands). Claude Code is now at v2.1.71 with 57 built-in commands, 5 bundled skills, and 12 aliases. Users cannot tab-complete new commands like `/chrome`, `/diff`, `/feedback`, `/insights`, `/loop`, and others.

## What Changes

- Add 15 new built-in commands: `/chrome`, `/diff`, `/feedback`, `/insights`, `/install-slack-app`, `/keybindings`, `/mobile`, `/passes`, `/reload-plugins`, `/remote-control`, `/skills`, `/stickers`, `/upgrade`, `/loop`, `/claude-api`
- Add 12 aliases for better discoverability: `/allowed-tools`, `/android`, `/app`, `/bug`, `/checkpoint`, `/continue`, `/ios`, `/new`, `/quit`, `/rc`, `/reset`, `/settings`
- Remove 4 commands no longer in docs: `/bashes`, `/teleport`, `/todos`, `/worktree`
- Update version comment and command count in `claude-completion.bash`
- Update command count and version reference in `README.md`

## Capabilities

### New Capabilities

(none - this is a data update to an existing capability)

### Modified Capabilities

(none - no spec-level behavior changes, only updating the command list data)

## Impact

- `claude-completion.bash`: Update the `builtin_commands` array (lines 46-55) and version comment
- `README.md`: Update command count and version reference
- No functional/behavioral changes to completion logic
