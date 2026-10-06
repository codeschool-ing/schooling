#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh           # needs uv, and the network the first time
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the project, rebuilt by ../../lab.sh at step 7 in /home/ana/shipquote,
#     with its virtual environment;
#   - mutate.py, beside this script, copied into the project; it is shown in
#     full in the section "mutation";
#   - in "no-asserts" and "gaming", the test files shown in those sections,
#     written here and deleted afterwards;
#   - in "diff-coverage", the surcharge shown in the section, written into
#     shipquote/quote.py with a small Python edit and undone with git checkout;
#   - in "exclusions", one line added to pyproject.toml, undone the same way.
#
# The last block, "go-cover", runs in this repository's own checkout rather
# than in shipquote, with Go 1.25.0, the version go.mod names.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16, pytest 9.1.1,
# coverage 7.16.2, TZ=America/Sao_Paulo. Run as root with HOME=/home/ana and
# USER=ana, so the paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
bash "$LAB" stage 7 >/dev/null && bash "$LAB" venv "$HOME/shipquote" >/dev/null 2>&1
cd "$HOME/shipquote" || exit 1
export PATH="$HOME/shipquote/.venv/bin:$PATH"
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block measure
run 'coverage run -m pytest -q'
run 'coverage report'

block line-only
run 'coverage run --rcfile=/dev/null --source=shipquote -m pytest -q tests/test_dispatch.py -k "after_two or friday"'
run 'coverage report --rcfile=/dev/null -m --include=shipquote/dispatch.py'

block branch
run 'coverage run -m pytest -q tests/test_dispatch.py -k "after_two or friday"'
run 'coverage report -m --include=shipquote/dispatch.py'

block no-asserts
cat > tests/test_money_runs.py <<'PY'
from shipquote.money import brl, split


def test_brl_runs():
    brl(123456)
    brl(1205)


def test_split_runs():
    split(10000, 3)
    try:
        split(10000, 0)
    except ValueError:
        pass
PY
run 'coverage run -m pytest -q tests/test_money_runs.py'
run 'coverage report -m --include=shipquote/money.py'
sed -i 's/{centavos:02d}/{centavos}/' shipquote/money.py
run 'python -m pytest -q tests/test_money_runs.py'
git checkout -q shipquote/money.py
rm tests/test_money_runs.py

block mutation
cp "$HERE/mutate.py" .
run 'python mutate.py'
rm mutate.py

block fail-under
run 'coverage run -m pytest -q > /dev/null; coverage report --fail-under=85 | tail -1; echo "exit status $?"'
run 'coverage report --fail-under=85 > /dev/null; echo "exit status $?"'

block gaming
cat > tests/test_touch_everything.py <<'PY'
from unittest import mock

from shipquote.carrier import CarrierClient
from shipquote.mailer import SmtpMailer


def test_the_client_can_be_used():
    try:
        CarrierClient("http://carrier.example", "t",
                      opener=mock.MagicMock()).rate("01310100", 1)
    except Exception:
        pass


def test_the_mailer_can_be_used():
    with mock.patch("smtplib.SMTP"):
        SmtpMailer("smtp.example").send("bia@example.org", "s", "b")
PY
run 'coverage run -m pytest -q | tail -1; coverage report | tail -1'
run 'coverage report --fail-under=85 > /dev/null; echo "exit status $?"'
rm tests/test_touch_everything.py

block diff-coverage
python3 - <<'PY'
p = "shipquote/quote.py"
s = open(p).read()
s = s.replace("    extra = (weight_g - 1) // 500\n",
              "    extra = (weight_g - 1) // 500\n"
              "    if weight_g > 30_000:           # heavy parcels go by road freight\n"
              "        return BASE[zone] * 3 + extra * EXTRA_PER_500G\n")
open(p, "w").write(s)
PY
run 'git diff --stat'
run 'coverage run -m pytest -q | tail -1; coverage report | tail -1'
run 'coverage report -m --include=shipquote/quote.py'
git checkout -q shipquote/quote.py

block exclusions
run 'coverage run -m pytest -q > /dev/null; coverage report -m --include=shipquote/app.py'
run 'sed -n 58,67p shipquote/app.py'
sed -i 's/^show_missing = true$/show_missing = true\nexclude_also = ["if __name__ == .__main__.:"]/' pyproject.toml
run 'git diff pyproject.toml | tail -4'
run 'coverage report -m --include=shipquote/app.py'
git checkout -q pyproject.toml

block combine
rm -f .coverage .coverage.*
run 'coverage run -p -m pytest -q -m "not functional and not acceptance" | tail -1'
run 'coverage run -p -m pytest -q -m "functional or acceptance" | tail -1'
run 'ls .coverage.* | wc -l'
run 'coverage combine'
run 'coverage report | tail -1'

block go-cover
REPO=$(cd "$HERE/../../../../../.." && pwd)
cd "$REPO" || exit 1
export GOTOOLCHAIN=go1.25.0
gorun() { printf 'ana@laptop:~/schooling$ %s\n' "$*"; bash -c "$*" 2>&1; }
go test ./internal/grade/ ./internal/trackblock/ >/dev/null 2>&1   # fills the module cache first
gorun 'go test -count=1 -cover ./internal/grade/ ./internal/trackblock/'
gorun 'go test -coverprofile=/tmp/grade.out ./internal/grade/ > /dev/null; go tool cover -func=/tmp/grade.out | sort -k3 -n | head -4'
