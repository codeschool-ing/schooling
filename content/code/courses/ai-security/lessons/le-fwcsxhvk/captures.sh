#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of ai-security, as a script that
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
# ticket, its messages and the reply in data/reply-4471.txt were written by the
# course: NO MODEL WAS CALLED, and the reply stands for what a provider would
# send back so that `guard restore` has something to restore. The people, the
# CPFs and the phone number are invented; lab.sh's header says so in full.
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

block who
on 'cat data/ticket-4471.json'

block minimise
on 'cat data/purposes.json'
on 'guard minimise data/ticket-4471.json --purpose summarise-dispute; echo "exit $?"'
on 'ls outbox vault 2>&1'
on 'guard minimise data/ticket-4471.json --purpose summarise-dispute --sensitive remove'
on 'cat outbox/TK-4471.json'
on 'cat vault/TK-4471.json'
on 'cat data/reply-4471.txt'
on 'guard restore vault/TK-4471.json data/reply-4471.txt'

block sensitive
on "guard sensitive 'I was in hospital for a week with a kidney infection'"
on "guard sensitive 'I spent a week in bed with a fever and the doctor said rest'"
on "guard sensitive 'My son has autism and I can only work at night'"
