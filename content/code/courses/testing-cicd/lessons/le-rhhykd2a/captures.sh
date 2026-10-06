#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh           # needs uv, and the network the first time
#
# What is STAGED rather than typed, and not shown in the lesson: the project,
# rebuilt by ../../lab.sh at its last step in /home/ana/shipquote, with its
# virtual environment; and the two deliberate bugs in "first-test" and
# "what-to-test", each written into a file with sed just before the run that
# shows it and taken out again with `git checkout` right after.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16, pytest 9.1.1,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana
LAB=$(cd "$(dirname "$0")/../.." && pwd)/lab.sh
bash "$LAB" stage last >/dev/null && bash "$LAB" venv "$HOME/shipquote" >/dev/null 2>&1
cd "$HOME/shipquote" || exit 1
export PATH="$HOME/shipquote/.venv/bin:$PATH"
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block first-run
run 'python -m pytest tests/test_money.py -v'

block first-fail
sed -i 's/{centavos:02d}/{centavos}/' shipquote/money.py
run 'python -m pytest tests/test_money.py'
git checkout -q shipquote/money.py

block float
run "python3 -c 'print(0.1 + 0.2 == 0.3, 0.1 + 0.2)'"
run "python3 -c 'print(10 + 20 == 30)'"

block unit
run 'python -m pytest tests/test_quote.py -v'

block integration
run 'python -m pytest -m integration -v'

block functional-by-hand
SHIPQUOTE_PORT=8080 setsid python -m shipquote.app >/tmp/shipquote-l1.log 2>&1 </dev/null &
pid=$!
sleep 1
run "curl -s 'http://127.0.0.1:8080/quote?cep=01310-100&weight=1200&subtotal=5000'; echo"
run "curl -s -i 'http://127.0.0.1:8080/quote?cep=abc&weight=1200'; echo"
kill "$pid"

block functional
run 'python -m pytest -m functional -v'

block acceptance
run 'python -m pytest -m acceptance -v'

block layers
run 'python -m pytest -q -m "not integration and not functional and not acceptance"'
run 'python -m pytest -q -m "integration or functional or acceptance"'
run 'python -m pytest -q --durations=4'

block boundary
sed -i 's/subtotal_cents >= FREE_FROM/subtotal_cents > FREE_FROM/' shipquote/quote.py
run 'python -m pytest tests/test_quote.py -q'
git checkout -q shipquote/quote.py

block select
run 'python -m pytest --collect-only -q -m "not functional and not acceptance" | tail -1'
run 'python -m pytest -q -k free'
run 'python -m pytest -q -m smoke; echo "exit status $?"'
