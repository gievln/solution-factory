#!/usr/bin/env bash
# Blocks gated skills until the matching human approval file exists in the opportunity workspace.
set -euo pipefail

input="$(cat)"
prompt="$(printf '%s' "$input" | jq -r '.prompt // ""')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"

block() {
  jq -n --arg r "$1" '{decision: "block", reason: $r}'
  exit 0
}

case "$prompt" in
  /scaffold-poc*|/solution-factory:scaffold-poc*)
    [[ -f "$cwd/approvals/architecture.approved" ]] ||
      block "Gate 1 not passed: an architect must review architecture/options.md and create approvals/architecture.approved."
    ;;
  /pitch*|/solution-factory:pitch*)
    [[ -f "$cwd/approvals/poc.approved" ]] ||
      block "Gate 2 not passed: an engineer must run the POC and create approvals/poc.approved."
    ;;
esac

exit 0
