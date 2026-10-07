#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh           # needs uv, and the network the first time
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. Lesson 1 shows the project
# at step 5 whole; this lesson shows what step 6 adds (mailer.py in "mock",
# the contract tests and the new pyproject.toml in "contract"), the carrier
# stand-in in "stub" and the throwaway test file in "patching", each whole.
# `../../lab.sh shown` fails this script before its first block if any of
# them is not the file ../../lab.sh wrote, and the throwaway file is written
# from the section's own block. What is STAGED rather than typed:
#   - the project, rebuilt by ../../lab.sh at step 6 in /home/ana/shipquote,
#     with its virtual environment;
#   - in "drift", SmtpMailer.send renamed to deliver with sed, and the step 5
#     version of tests/test_orders.py put back with `git show`, both undone
#     with `git checkout` afterwards;
#   - the carrier stand-in from `lab.sh carrier`, started in the background on
#     127.0.0.1:9090 with the token below, which is a lab value and opens
#     nothing; in "contract-drift" its answer key is renamed with the sed the
#     section shows, and the stand-in restarted.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16, pytest 9.1.1,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
bash "$LAB" stage 6 >/dev/null && bash "$LAB" venv "$HOME/shipquote" >/dev/null 2>&1
bash "$LAB" carrier "$HOME/carrier"
bash "$LAB" shown "$HERE" - -patching || exit 1
cd "$HOME/shipquote" || exit 1
export PATH="$HOME/shipquote/.venv/bin:$PATH"
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
TOKEN=lab-token-not-a-secret
carrier_up() {
  CARRIER_TOKEN=$TOKEN CARRIER_DELAY=${1:-0} setsid python3 "$HOME/carrier/server.py" </dev/null >/dev/null 2>&1 &
  CARRIER_PID=$!
  sleep 1
}

block doubles
run 'python -m pytest tests/test_carrier.py tests/test_orders.py -v'

block mock-anything
run "python3 -c '
from unittest import mock
mailer = mock.Mock()
mailer.sned(to=\"bia@example.org\")
print(mailer.sned.call_args)
print(mailer.anything.at.all())
'"

block autospec
run "python3 -c '
from unittest import mock
from shipquote.mailer import SmtpMailer
mailer = mock.create_autospec(SmtpMailer, instance=True)
mailer.sned(to=\"bia@example.org\")
'"

block drift
sed -i 's/    def send(self, to, subject, body):/    def deliver(self, to, subject, body):/' shipquote/mailer.py
run 'git diff --stat'
git show HEAD~1:tests/test_orders.py > tests/test_orders.py
run 'python -m pytest tests/test_orders.py -q'
git checkout -q tests/test_orders.py
run 'python -m pytest tests/test_orders.py -q --tb=line'
git checkout -q shipquote/mailer.py

block patch-trap
bash "$LAB" fence "$HERE/patching.md" tests/test_patch_trap.py > tests/test_patch_trap.py || exit 1
run 'python -m pytest tests/test_patch_trap.py -q --tb=line'
rm tests/test_patch_trap.py

block contract-skip
run 'python -m pytest -m contract -v -rs'

block contract-run
carrier_up
run "CARRIER_URL=http://127.0.0.1:9090 CARRIER_TOKEN=$TOKEN python -m pytest -m contract -q"

block contract-drift
kill "$CARRIER_PID"; sleep 0.5
sed -i 's/{"cents": 1500/{"price_cents": 1500/' "$HOME/carrier/server.py"
carrier_up
run 'python -m pytest tests/test_carrier.py -q'
run "CARRIER_URL=http://127.0.0.1:9090 CARRIER_TOKEN=$TOKEN python -m pytest -m contract -q --tb=line"
kill "$CARRIER_PID"; sleep 0.5
bash "$LAB" carrier "$HOME/carrier"

block slow
carrier_up 3
run "time python3 -c '
from shipquote.carrier import CarrierClient, price
client = CarrierClient(\"http://127.0.0.1:9090\", \"$TOKEN\", timeout=2)
print(price(client, \"01310-100\", 1200, 5000))
'"
kill "$CARRIER_PID"
