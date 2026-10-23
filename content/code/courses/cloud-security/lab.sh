#!/usr/bin/env bash
# The author's lab for cloud-security. The student never sees this file: lesson
# 1 shows them how to build the same lab on their own computer, and every
# transcript in the course was recorded in a lab built that way.
#
#   bash lab.sh build             # lesson 1's captures: the lab, from nothing
#   bash lab.sh capture LESSON    # one lesson's captures, pasted into its prose
#   bash lab.sh check             # every lesson recorded again and compared,
#                                 # changing nothing: what the prose shows is
#                                 # what the lab prints today
#
# LAB_ROOT (default /opt/cslab) holds the lab's home directory, moto's pid
# file, the lock and the downloads later lessons make. PYTHON3_DIR, if set,
# names a directory whose `python3` is Ubuntu 24.04's 3.12; the recording
# machine's own python3 is 3.13, so it was /opt/cslab/py312 there.
#
# THERE IS NO CLOUD ACCOUNT IN THIS COURSE. The AWS every lesson talks to is
# moto 5.2.3 on 127.0.0.1:4567, driven by the AWS CLI 2.37.4, region sa-east-1,
# credentials test/test: the lab the four AWS courses settled, built the same
# way. Azure and Google Cloud are taught from their documentation, and every
# lesson says in its prose which of its claims were not run.
#
# What reaches the internet: the downloads lesson 1 makes (the AWS CLI, moto
# from PyPI), one request to the real STS with moto's placeholder key, which
# AWS refuses (lesson 1, "when-setup-fails"), the downloads of lessons 12 and 13
# (Terraform and its AWS provider from releases.hashicorp.com, Checkov and
# pip-audit from PyPI) and pip-audit's question to PyPI about known
# vulnerabilities.
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
  build) one le-9hn6cbfc ;;
  capture) one "$2" ;;
  check)
    bad=0
    for id in $(python3 -c "import json; print(' '.join(json.load(open('$HERE/course.json'))['lessons']))"); do
      one "$id" --check || bad=1
    done
    exit $bad ;;
  *) sed -n '2,10p' "$0"; exit 1 ;;
esac
