#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ai-security, as a script that
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
# applications, the companies in them, data/cnpj-registry.json (a stand-in for
# the Receita Federal's public CNPJ data) and the usage in
# data/partner-usage.jsonl were WRITTEN BY THE COURSE. No registry and no
# provider was queried. The date the applications are judged on is passed as
# --now 2026-09-30.
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
on 'head -1 data/applications.jsonl'
on 'guard cnpj 19.384.756/0001-01'
on 'guard cnpj 19.384.756/0001-00'
on 'guard onboard data/applications.jsonl --now 2026-09-30'

block usecase
on 'cat data/use-cases.json'
on 'guard onboard data/applications.jsonl --now 2026-09-30 --id ap-03'
on "grep ap-02 data/applications.jsonl"

block tiers
on 'cat data/tiers.json'
on 'guard drift p-docelar'
