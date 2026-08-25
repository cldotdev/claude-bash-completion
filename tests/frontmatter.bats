#!/usr/bin/env bats

setup() {
  FIXTURES="$BATS_TEST_TMPDIR/fixtures"
  mkdir -p "$FIXTURES"

  # Skill with name in frontmatter
  mkdir -p "$FIXTURES/skills/my-skill"
  cat > "$FIXTURES/skills/my-skill/SKILL.md" << 'FIXTURE'
---
name: custom-name
description: A test skill
---
# Content
FIXTURE

  # Skill with quoted name
  mkdir -p "$FIXTURES/skills/quoted-skill"
  cat > "$FIXTURES/skills/quoted-skill/SKILL.md" << 'FIXTURE'
---
name: "quoted-name"
description: A test skill
---
# Content
FIXTURE

  # Skill with single-quoted name
  mkdir -p "$FIXTURES/skills/single-quoted"
  cat > "$FIXTURES/skills/single-quoted/SKILL.md" << 'FIXTURE'
---
name: 'single-quoted-name'
---
# Content
FIXTURE

  # Skill with colon in name
  mkdir -p "$FIXTURES/skills/colon-skill"
  cat > "$FIXTURES/skills/colon-skill/SKILL.md" << 'FIXTURE'
---
name: "dev:rails"
---
# Content
FIXTURE

  # Skill without name in frontmatter
  mkdir -p "$FIXTURES/skills/no-name"
  cat > "$FIXTURES/skills/no-name/SKILL.md" << 'FIXTURE'
---
description: No name field
---
# Content
FIXTURE

  # Skill without frontmatter
  mkdir -p "$FIXTURES/skills/no-frontmatter"
  cat > "$FIXTURES/skills/no-frontmatter/SKILL.md" << 'FIXTURE'
# Just markdown, no frontmatter
FIXTURE

  # Command with name in frontmatter
  mkdir -p "$FIXTURES/commands"
  cat > "$FIXTURES/commands/my-cmd.md" << 'FIXTURE'
---
name: renamed-cmd
---
# Content
FIXTURE

  # Command without frontmatter
  cat > "$FIXTURES/commands/plain.md" << 'FIXTURE'
# Just a command
FIXTURE

  # Source the completion script to get the helper function
  source "$BATS_TEST_DIRNAME/../claude-completion.bash"
}

@test "extracts name from frontmatter" {
  _claude_frontmatter_name "$FIXTURES/skills/my-skill/SKILL.md"
  [[ "$REPLY" == "custom-name" ]]
}

@test "extracts double-quoted name" {
  _claude_frontmatter_name "$FIXTURES/skills/quoted-skill/SKILL.md"
  [[ "$REPLY" == "quoted-name" ]]
}

@test "extracts single-quoted name" {
  _claude_frontmatter_name "$FIXTURES/skills/single-quoted/SKILL.md"
  [[ "$REPLY" == "single-quoted-name" ]]
}

@test "extracts name containing colon" {
  _claude_frontmatter_name "$FIXTURES/skills/colon-skill/SKILL.md"
  [[ "$REPLY" == "dev:rails" ]]
}

@test "returns empty for frontmatter without name" {
  _claude_frontmatter_name "$FIXTURES/skills/no-name/SKILL.md"
  [[ -z "$REPLY" ]]
}

@test "returns empty for file without frontmatter" {
  _claude_frontmatter_name "$FIXTURES/skills/no-frontmatter/SKILL.md"
  [[ -z "$REPLY" ]]
}

@test "returns empty for nonexistent file" {
  _claude_frontmatter_name "$FIXTURES/does-not-exist.md"
  [[ -z "$REPLY" ]]
}
