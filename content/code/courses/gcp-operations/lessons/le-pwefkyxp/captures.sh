#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of gcp-operations.
#
#   bash captures.sh
#
# findings.jsonl is written by the course, as the lesson says, and taken out
# of it with from_lesson. Nothing here comes from Security Command Center.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/triage.md" findings.jsonl > findings.jsonl

block count
run 'wc -l findings.jsonl'
run "jq -s -c 'group_by(.severity) | map({severity: .[0].severity, count: length})' findings.jsonl"
block open
run "jq -c 'select(.state == \"ACTIVE\" and .mute == \"UNMUTED\")' findings.jsonl | wc -l"
run "jq -r 'select(.state == \"ACTIVE\" and .mute == \"UNMUTED\" and (.severity == \"CRITICAL\" or .severity == \"HIGH\")) | [.findingClass, .severity, .category] | @tsv' findings.jsonl"
block threat
run "jq -r 'select(.findingClass == \"THREAT\") | [.eventTime, .category, .resourceName] | @tsv' findings.jsonl"
