#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ai-security, as a script that
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
# requests in data/inputs.jsonl and the model replies in data/outputs.jsonl
# were WRITTEN BY THE COURSE; no model produced any reply. `guard retry` uses
# them in place of a model's successive attempts, and says so in its code.
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

block inputs
on 'cat data/input-rules.json'
on 'head -1 data/inputs.jsonl'
on 'guard check-in data/inputs.jsonl; echo "exit $?"'

block outputs
on 'cat data/output-schema.json'
on 'guard check-out data/outputs.jsonl --id out-1 --show'
on 'guard check-out data/outputs.jsonl --id out-2 --show'
on 'guard check-out data/outputs.jsonl'
on 'cat data/allowed-hosts.json'

block failing
on 'guard retry out-3 out-1; echo "exit $?"'
on 'guard retry out-2 out-7; echo "exit $?"'
