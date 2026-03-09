# Variables and Quoting

## Always Quote

- Double-quote all variable expansions: `"$var"`, `"${var}"`.
- Double-quote command substitutions: `"$(command)"`.
- Only omit quotes when intentional word splitting or globbing is needed.

## Variable Declarations

- Use `local` for all variables inside functions.
- Use `readonly` for constants: `readonly CONFIG_DIR="/etc/myapp"`.
- Use `UPPER_CASE` for exported and constant variables.
- Use `snake_case` for local and function-scoped variables.

## Parameter Expansion

- Default values: `${var:-default}` (use default if unset or empty).
- Required values: `${var:?error message}` (exit with error if unset).
- Substrings: `${var#pattern}` (remove prefix), `${var%pattern}` (remove suffix).
- Avoid nested substitution when a simple variable suffices.

## Arrays

- Use arrays instead of space-separated strings for lists.
- Iterate with: `for item in "${array[@]}"; do`.
- Get length with: `${#array[@]}`.
- Append with: `array+=("new_item")`.

## Naming

- Functions: `snake_case`.
- Local variables: `snake_case`.
- Constants and exports: `UPPER_SNAKE_CASE`.
- Avoid single-letter names except for loop counters.
