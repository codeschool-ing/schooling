#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: tiers.py, redact.py,
# scan.py, sweep.py, the 22 calls, retention.json and holds.json are exactly
# what the lesson prints, and detect.py is lesson 5's. It prints each command
# after a prompt, ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: every record in the log, prompts AND replies; no model
# produced any of them. Every CPF, card, phone, address and key in them is
# invented: the CPFs have valid check digits on purpose, the cards are the
# networks' published test numbers, and the AWS key is the one Amazon's own
# documentation uses as an example. No model is called in this lesson.
#
# Recorded with Python 3.12.3 (Ubuntu 24.04's), TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/home/ana}
mkdir -p "$HOME/.py"
ln -sf "$(command -v python3.12)" "$HOME/.py/python3"
export PATH=$HOME/.py:$PATH
GUARD_HOME=$HOME bash "$here/../../lab.sh" reset >/dev/null || exit 1
cd "$HOME/guard"
export PATH=$HOME/guard/bin:$PATH
on() { printf 'ana@lab:~/guard$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block raw
on 'guard tiers'
on 'head -1 logs/raw/2026-09-29.jsonl'

block tiers
on 'ls logs'
on 'head -1 logs/metrics/2026-09-29.jsonl'
on 'cat retention.json'

block key
on 'guard redact logs/raw/2026-06-02.jsonl'

block scan
on 'guard scan logs/raw'

block show
on 'guard scan --show logs/raw'

block strict
on 'guard scan --strict logs/raw'

block shapes
on 'guard redact logs/raw/2026-09-29.jsonl'
on 'guard redact logs/raw/2026-07-28.jsonl'
on 'guard redact logs/raw/2026-04-21.jsonl'

block check
on 'guard sweep --now 2026-09-30 --check; echo "exit $?"'

block holds
on 'cat holds.json'

block sweep
on 'guard sweep --now 2026-09-30 --dry-run | tail -4'
on 'guard sweep --now 2026-09-30 | tail -4'
on 'guard sweep --now 2026-09-30 --check; echo "exit $?"'
on 'ls logs/raw'
