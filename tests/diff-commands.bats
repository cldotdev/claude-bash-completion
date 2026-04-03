#!/usr/bin/env bats

# Tests for the extraction regex patterns used by diff-commands.sh.
# Uses sample strings matching the Claude binary's minified JS format.

setup() {
  SAMPLE="$BATS_TEST_TMPDIR/sample.txt"

  # Simulated strings output from a Claude binary
  cat > "$SAMPLE" << 'SAMPLE'
type:"local",name:"clear",description:"Clear conversation history and free up context",aliases:["reset","new"]
type:"local-jsx",name:"compact",description:"Clear conversation history but keep a summary in context"
type:"local-jsx",name:"config",description:"Open config panel"
type:"prompt",name:"commit",description:"Generate Git commit message"
type:"local",name:"heapdump",description:"Dump the JS heap to ~/Desktop",isHidden:!0
type:"local",name:"bridge-kick",description:"Inject bridge failure states",isEnabled:()=>!1
type:"local-jsx",name:"tag",description:"Toggle a searchable tag",isEnabled:()=>false
type:"local",name:"thinkback-play",description:"Play the thinkback animation",isHidden:true
type:"prompt",name:"mcp__",description:"Internal MCP prefix"
type:"local-jsx",name:"exit",aliases:["quit"]
type:"local-jsx",name:"plugin",aliases:["plugins","marketplace"]
type:"prompt",aliases:["bug"],name:"feedback"
type:"local-jsx",aliases:["settings"],name:"config"
name:"chrome",description:"Claude in Chrome settings",type:"local-jsx"
e3({name:"batch",description:"Run batch operations"
oZ7({name:"security-review",description:"Security review"
e3({name:"disabled-skill",description:"A disabled skill",isEnabled:()=>!1,other:"stuff"}
name:"crmsh",case_insensitive:!0,aliases:["crm","pcmk"]
SAMPLE

  # Source the extraction functions
  source "$BATS_TEST_DIRNAME/../scripts/diff-commands.sh" --source-only
}

@test "extracts primary command names" {
  result=$(extract_primary_names < "$SAMPLE")
  [[ "$result" == *"clear"* ]]
  [[ "$result" == *"compact"* ]]
  [[ "$result" == *"config"* ]]
  [[ "$result" == *"commit"* ]]
  [[ "$result" == *"exit"* ]]
}

@test "excludes isHidden commands" {
  result=$(extract_excluded_names < "$SAMPLE")
  [[ "$result" == *"heapdump"* ]]
  [[ "$result" == *"thinkback-play"* ]]
}

@test "excludes isEnabled false commands" {
  result=$(extract_excluded_names < "$SAMPLE")
  [[ "$result" == *"bridge-kick"* ]]
  [[ "$result" == *"tag"* ]]
}

@test "excludes mcp__ prefix" {
  result=$(extract_excluded_names < "$SAMPLE")
  [[ "$result" == *"mcp__"* ]]
}

@test "extracts aliases (name before aliases)" {
  result=$(extract_aliases < "$SAMPLE")
  [[ "$result" == *"reset"* ]]
  [[ "$result" == *"new"* ]]
  [[ "$result" == *"quit"* ]]
  [[ "$result" == *"plugins"* ]]
  [[ "$result" == *"marketplace"* ]]
}

@test "extracts aliases (aliases before name)" {
  result=$(extract_aliases < "$SAMPLE")
  [[ "$result" == *"bug"* ]]
  [[ "$result" == *"settings"* ]]
}

@test "extracts commands with name before type" {
  result=$(extract_primary_names < "$SAMPLE")
  [[ "$result" == *"chrome"* ]]
}

@test "extracts e3() registered commands" {
  result=$(extract_primary_names < "$SAMPLE")
  [[ "$result" == *"batch"* ]]
}

@test "extracts oZ7() registered commands" {
  result=$(extract_primary_names < "$SAMPLE")
  [[ "$result" == *"security-review"* ]]
}

@test "excludes e3() commands with static isEnabled false" {
  result=$(extract_excluded_names < "$SAMPLE")
  [[ "$result" == *"disabled-skill"* ]]
}

@test "excludes rate-limit-options" {
  result=$(extract_excluded_names < "$SAMPLE")
  [[ "$result" == *"rate-limit-options"* ]]
}

@test "aliases exclude non-command patterns" {
  result=$(extract_aliases < "$SAMPLE")
  [[ "$result" != *"crm"* ]]
  [[ "$result" != *"pcmk"* ]]
}

@test "final command list excludes hidden and includes aliases" {
  result=$(build_command_list < "$SAMPLE")
  # Included: primary names + aliases
  [[ "$result" == *"clear"* ]]
  [[ "$result" == *"reset"* ]]
  [[ "$result" == *"new"* ]]
  [[ "$result" == *"commit"* ]]
  [[ "$result" == *"bug"* ]]
  [[ "$result" == *"chrome"* ]]
  [[ "$result" == *"batch"* ]]
  [[ "$result" == *"security-review"* ]]
  # Excluded: hidden/disabled/internal
  [[ "$result" != *"heapdump"* ]]
  [[ "$result" != *"bridge-kick"* ]]
  [[ "$result" != *"thinkback-play"* ]]
  [[ "$result" != *"mcp__"* ]]
  [[ "$result" != *"tag"* ]]
  [[ "$result" != *"disabled-skill"* ]]
  [[ "$result" != *"rate-limit-options"* ]]
}
