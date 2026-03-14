## Why

The built-in commands list in `claude-completion.bash` is outdated (v2.1.71, 77 commands). Claude Code is now at v2.1.76 with 3 new built-in commands and 1 removed command. Users cannot tab-complete `/btw`, `/color`, or `/effort`, and the obsolete `/output-style` still appears in completions.

## What Changes

- Add 3 new built-in commands: `/btw`, `/color`, `/effort`
- Remove 1 obsolete command: `/output-style` (folded into `/config`)
- Update version comment and command count in `claude-completion.bash`
- Update command count and version reference in `README.md`

## Capabilities

### New Capabilities

(none - this is a data update to an existing capability)

### Modified Capabilities

(none - no spec-level behavior changes, only updating the command list data)

## Impact

- `claude-completion.bash`: Update the `builtin_commands` array and version comment
- `README.md`: Update command count and version reference
- No functional/behavioral changes to completion logic
