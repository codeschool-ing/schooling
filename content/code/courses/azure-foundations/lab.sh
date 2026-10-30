#!/usr/bin/env bash
# The author's lab for azure-foundations. The student never sees this file:
# lesson 1 shows them how to build the same lab on their own computer, and every
# transcript in the course was recorded in a lab built that way.
#
#   bash lab.sh build             # lesson 1's captures: the lab, from nothing
#   bash lab.sh capture LESSON    # one lesson's captures, pasted into its prose
#   bash lab.sh check             # every lesson recorded again and compared,
#                                 # changing nothing: what the prose shows is
#                                 # what the lab prints today
#
# LAB_ROOT (default /opt/azlab) holds the lab's home directory and the lock.
# PYTHON3_DIR, if set, names a directory whose `python3` is Ubuntu 24.04's 3.12
# (see from-lessons.sh).
#
# THERE IS NO AZURE ACCOUNT IN THIS COURSE, and nothing imitates one. What runs
# is the real Azure CLI, Bicep CLI and Terraform with Microsoft's providers,
# none of which needs an account to build, check or refuse; the Azure Identity
# library; and three public services: Microsoft Entra ID's sign-in endpoints,
# which refuse a made-up tenant, the public DNS, and the GitHub copy of the
# built-in policy definitions. Whatever needs Azure Resource Manager is taught
# from Microsoft's documentation and the prose says it was not run.
#
# `check` MAY REPORT FOUR BLOCKS, and none of them is drift in the lab: each
# reads something on the internet that Microsoft changes on its own schedule,
# and no sentence of prose quotes the part that moves.
#   lesson 3  the-table          Microsoft's move-support page, edited often
#   lesson 19 dig-login          login.microsoftonline.com's CNAME chain, which
#   lesson 22 (its dig blocks)   ends in trafficmanager.net or akadns.net by turn
#   lesson 21 dig-portal         portal.azure.com's chain, the same way
# The run recorded on 2026-10-30 reported none of them. Anything else that
# differs is a transcript that no longer matches its lab.
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
  build) one le-s4559705 ;;
  capture) one "$2" ;;
  check)
    bad=0
    for id in $(python3 -c "import json; print(' '.join(json.load(open('$HERE/course.json'))['lessons']))"); do
      one "$id" --check || bad=1
    done
    exit $bad ;;
  *) sed -n '2,32p' "$0"; exit 1 ;;
esac
