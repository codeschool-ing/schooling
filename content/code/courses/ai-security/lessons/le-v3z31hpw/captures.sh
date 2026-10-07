#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME, so nothing of yours
# is touched, and prints each command after a prompt, ana@lab:~/guard$,
# followed by what it printed.
#
# What is STAGED rather than typed: the whole of ~/guard, built by lab.sh. The
# log's records, prompts and replies alike, were written by the course and no
# model produced them; lab.sh's header says so in full. The date the sweep is
# run on is passed as --now 2026-09-30, so the ages it prints do not depend on
# the day this script runs.
#
# Recorded with Python 3.11, TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/var/tmp/ai-security}
mkdir -p "$HOME"
bash "$here/../../lab.sh" reset >/dev/null
cd "$HOME/guard"
export PATH=$HOME/guard/bin:$PATH
on() { printf 'ana@lab:~/guard$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block keep
on 'head -1 logs/raw/2026-09-29.jsonl'
on 'ls logs'
on 'head -1 logs/metrics/2026-09-29.jsonl'
on 'cat retention.json'
on 'guard redact logs/raw/2026-06-02.jsonl'

block redaction
on 'guard scan logs/raw'
on 'guard scan --show logs/raw'
on 'guard redact logs/raw/2026-09-29.jsonl'
on 'guard redact logs/raw/2026-07-28.jsonl'
on 'guard redact logs/raw/2026-04-21.jsonl'
on 'guard scan --strict logs/raw'

block retention
on 'cat holds.json'
on 'guard sweep --now 2026-09-30 --check; echo "exit $?"'
on 'guard sweep --now 2026-09-30 --dry-run | tail -4'
on 'guard sweep --now 2026-09-30 | tail -4'
on 'guard sweep --now 2026-09-30 --check; echo "exit $?"'
on 'ls logs/raw'
