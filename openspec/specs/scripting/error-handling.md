# Error Handling

## Strict Mode

All scripts must start with strict mode after the shebang:

```bash
set -euo pipefail
```

- `set -e`: Exit on any command failure.
- `set -u`: Treat unset variables as errors.
- `set -o pipefail`: Propagate pipe failures.

## Cleanup with Traps

Use `trap` to ensure cleanup runs on exit, error, or interrupt:

```bash
cleanup() {
  rm -f "$tmp_file"
}
trap cleanup EXIT
```

- Prefer `EXIT` over `ERR` for cleanup — it runs on both success and failure.
- Use `trap - EXIT` to disable a trap before re-raising.

## Error Messages

- Write error messages to stderr: `echo "error: message" >&2`
- Include the script name in error messages: `echo "${0##*/}: error: message" >&2`
- Provide actionable context (what failed, what to do about it).

## Exit Codes

- **0**: Success.
- **1**: General error.
- **2**: Usage error (invalid arguments, missing required options).
- Use named constants for project-specific exit codes.

## Guard Clauses

Check prerequisites early and fail fast:

```bash
command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }
[[ -f "$config_file" ]] || { echo "error: config not found: $config_file" >&2; exit 1; }
```
