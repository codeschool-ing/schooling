#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of ai-security, as a script that
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
# category names in data/owasp-llm-2025.json are the OWASP Top 10 for LLM
# Applications (2025); the one-line meanings and the mapping to this lab were
# WRITTEN BY THE COURSE.
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

block map
on "python3 -c \"import json; [print(r['id'], '-', r['meaning']) for r in json.load(open('data/owasp-llm-2025.json'))]\""
on 'guard owasp'

block gaps
on 'guard owasp --uncovered'
