#!/usr/bin/env bash
# The author's lab for gcp-foundations. The student never sees this file:
# lesson 1 shows them how to build the same lab on their own computer, and every
# transcript in the course was recorded in a lab built that way.
#
#   bash lab.sh build             # lesson 1's captures: the lab, from nothing
#   bash lab.sh capture LESSON    # one lesson's captures, pasted into its prose
#   bash lab.sh check             # every lesson recorded again and compared,
#                                 # changing nothing: what the prose shows is
#                                 # what the lab prints today
#
# The lab's home is /home/ana. LAB_ROOT (default /opt/gcplab) holds the
# emulator's pid file and log, and the lock. PYTHON3_DIR, if set, names a
# directory whose `python3` is Ubuntu 24.04's 3.12 (see from-lessons.sh).
#
# THERE IS NO GOOGLE CLOUD ACCOUNT IN THIS COURSE. What answers is the Google
# Cloud CLI 589.0.0, its Pub/Sub emulator on localhost:8085, and Terraform
# 1.16.4 with the hashicorp/google provider 8.7.0, which plans without asking
# Google anything. Some blocks send the placeholder token to Google's real APIs
# on purpose, and quote the refusal; each lesson's captures.sh says which.
#
# `check` IS EXPECTED TO REPORT SOME BLOCKS, and none of them is drift: each
# prints something no two runs share, and no sentence of prose quotes it. Each
# lesson's captures.sh names its own (the emulator's clock in its log, the
# memory a process holds, a token's expiry). Anything else that differs is a
# transcript that no longer matches its lab.
#
# A capture that changes its numbers changes the prose that quotes them: after
# `capture`, re-read every number the lesson's text cites.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

one() { # LESSON-ID [--check]
  local dir=$HERE/lessons/$1
  [ -f "$dir/captures.sh" ] || return 0
  bash "$dir/captures.sh" > "$OUT/$1.txt" 2>&1 || { echo "$1: captures.sh failed"; tail -20 "$OUT/$1.txt"; return 1; }
  python3 "$HERE/paste.py" "$dir" "$OUT/$1.txt" ${2:-}
}

case "${1:-}" in
  build) one le-jyyebc5b ;;
  capture) one "$2" ;;
  check)
    bad=0
    for id in $(python3 -c "import json; print(' '.join(json.load(open('$HERE/course.json'))['lessons']))"); do
      one "$id" --check || bad=1
    done
    exit $bad ;;
  *) sed -n '2,30p' "$0"; exit 1 ;;
esac
