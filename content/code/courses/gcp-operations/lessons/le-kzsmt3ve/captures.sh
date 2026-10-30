#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of gcp-operations.
#
#   bash captures.sh     # after lesson 10's captures, which leave checkout.log
#
# checkout.log is regenerated from lesson 10's genlogs.py, so the timeline is
# built from the same thirty minutes that lesson counted.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/../le-rvjt01k9/counters.md" genlogs.py > genlogs.py
python3 genlogs.py > checkout.log

block above
run "jq -r 'select(.message == \"payment retried\") | .timestamp[11:16]' checkout.log | sort | uniq -c | awk '\$1 > 5 {print \$2}' | sed -n '1p;\$p'"
block first-last
run "jq -r 'select(.message == \"payment retried\") | .timestamp' checkout.log | sort | sed -n '/T14:1[2-7]/p' | sed -n '1p;\$p'"
block orders
run "jq -r 'select(.timestamp[11:16] >= \"14:12\" and .timestamp[11:16] <= \"14:17\") | .message' checkout.log | sort | uniq -c"
