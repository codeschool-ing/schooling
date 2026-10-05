#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of ai-security, as a script that
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
# keys in keys/ are FIXED so that the ids repeat from run to run; a real key is
# random and lives in a secret store. The addresses in data/emails.txt and the
# requests in data/api-requests.jsonl were written by the lab from tables in
# guardlab/cli.py and guardlab/ratelimit.py. No provider was called.
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

block naive
on 'guard enduser --naive marcos.teixeira@example.com.br'
on 'head -3 data/emails.txt; wc -l data/emails.txt'
on 'guard reverse e99036a63befa4e2995bd6ba388d0586cfbc78dd4eb31af863f558d7fd630894 --list data/emails.txt'

block hmac
on 'guard enduser ac-7Q2M'
on 'guard enduser ac-9D4H'
on 'guard enduser ac-7Q2M --provider provider-b'
on 'guard reverse eu-fe47aa8e7cd5e1b6f8bc --list data/emails.txt; echo "exit $?"'

block limits
on 'head -3 data/api-requests.jsonl'
on 'guard ratelimit data/api-requests.jsonl --per-key 60'
on 'guard ratelimit data/api-requests.jsonl --per-key 60 --per-user 20'
