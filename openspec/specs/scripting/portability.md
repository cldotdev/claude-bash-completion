# Portability

## Shebang

- Use `#!/usr/bin/env bash` for scripts requiring bash features.
- Use `#!/bin/sh` only for POSIX-compliant scripts.

## Command Availability

- Check with `command -v` instead of `which`.
- Do not assume GNU coreutils — macOS ships BSD variants.
- Use `printf` over `echo` for consistent behavior across systems.

## Bash-Specific Features

These require bash and are not POSIX-compatible:

- `[[ ]]` (extended test), `(( ))` (arithmetic)
- Arrays, associative arrays
- `<(process substitution)`
- `${var,,}` (case conversion), `${var//pattern/replacement}` (pattern substitution)
- `set -o pipefail`

When POSIX compliance is required, avoid these and document the constraint in the project README.

## Path Handling

- Do not hardcode paths — use variables or `command -v`.
- Use `"$(cd "$(dirname "$0")" && pwd)"` to resolve script directory.
- Handle paths with spaces by always quoting.

## Temporary Files

- Use `mktemp` for temporary files and directories.
- Always clean up with a trap (see error-handling spec).
