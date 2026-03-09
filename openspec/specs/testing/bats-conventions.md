# Bats Conventions

## File Organization

- Test files in `test/` directory with `.bats` extension.
- One test file per script or module.
- Helper files in `test/test_helper/` or `test/helpers/`.

## Helper Libraries

Use the standard bats helper libraries:

- `bats-support`: Base helper for output formatting.
- `bats-assert`: Assertions (`assert_success`, `assert_failure`, `assert_output`, `assert_line`).
- `bats-file`: File system assertions (`assert_file_exists`, `assert_dir_exists`).

Load helpers at the top of each test file:

```bash
setup() {
  load "test_helper/bats-support/load"
  load "test_helper/bats-assert/load"
}
```

## Writing Tests

- Use `@test "description"` with clear, descriptive names.
- Use `run` to capture command output and status.
- Assert exit status with `assert_success` or `assert_failure`.
- Assert output with `assert_output`, `assert_line`, `refute_output`.
- Test both success and failure paths.
- Use `setup()` and `teardown()` for shared fixtures.
- Use `setup_file()` and `teardown_file()` for expensive per-file setup.

```bash
@test "prints usage when no arguments given" {
  run my_script
  assert_failure
  assert_output --partial "Usage:"
}
```

## Running Tests

- Local: `bats --formatter pretty test/`
- CI: `bats --formatter tap test/`
- Run changed file tests first, then full suite.
- Combine with ShellCheck: `shellcheck -x src/*.sh && bats test/`
