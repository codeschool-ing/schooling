#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh           # needs uv, and the network the first time
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. What step 7 adds is shown
# whole here (the factory, the rewritten store tests, the CSV, the table test
# and the property tests), and `../../lab.sh shown` fails this script before
# its first block if any of them is not the file ../../lab.sh wrote.
# What is STAGED rather than typed:
#   - the project, rebuilt by ../../lab.sh at step 7 in /home/ana/shipquote,
#     with its virtual environment, and /tmp/pytest-of-ana emptied first;
#   - in "scope-mismatch" and "scope-leak", the store fixture changed as the
#     diffs show, and in "scope-leak" the test shown in the section appended
#     to tests/test_store.py;
#   - in "table-change", zone N's base price raised from 2990 to 3090 with sed;
#   - in "property-fail", split replaced by the naive version shown in the
#     section;
#   each undone with `git checkout` straight after.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16, pytest 9.1.1,
# hypothesis 6.168.5, TZ=America/Sao_Paulo. Run as root with HOME=/home/ana
# and USER=ana, so the paths, pytest's temporary directory among them, read as
# Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
LAB=$(cd "$(dirname "$0")/../.." && pwd)/lab.sh
bash "$LAB" stage 7 >/dev/null && bash "$LAB" venv "$HOME/shipquote" >/dev/null 2>&1
bash "$LAB" shown "$(dirname "$LAB")/lessons/le-36z0asbh" || exit 1
rm -rf /tmp/pytest-of-ana
cd "$HOME/shipquote" || exit 1
export PATH="$HOME/shipquote/.venv/bin:$PATH"
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block setup-show
run 'python -m pytest tests/test_store.py --setup-show -q'

block scope-mismatch
python3 - <<'PY'
p = "tests/conftest.py"
s = open(p).read().replace("@pytest.fixture\ndef store(", '@pytest.fixture(scope="module")\ndef store(', 1)
open(p, "w").write(s)
PY
run 'python -m pytest tests/test_store.py -q -k saved'
git checkout -q tests/conftest.py

block scope-leak
python3 - <<'PY'
p = "tests/conftest.py"
s = open(p).read().replace(
    '@pytest.fixture\ndef store(tmp_path):\n    s = Store(tmp_path / "quotes.db")',
    '@pytest.fixture(scope="module")\ndef store(tmp_path_factory):\n    s = Store(tmp_path_factory.mktemp("db") / "quotes.db")', 1)
open(p, "w").write(s)
PY
cat >> tests/test_store.py <<'PY'


def test_a_new_store_has_no_quotes(store):
    assert store.recent(10) == []
PY
run 'git diff tests/conftest.py'
run 'python -m pytest tests/test_store.py -q --tb=line'
run 'python -m pytest tests/test_store.py -q -k no_quotes'
git checkout -q tests/conftest.py tests/test_store.py

block tmp-path
run 'python -m pytest tests/test_store.py -q'
run 'ls /tmp/pytest-of-ana/'
run 'find /tmp/pytest-of-ana/pytest-current/ -name "*.db"'

block factory-run
run 'python -m pytest tests/test_store.py -v'

block table
run 'python -m pytest tests/test_quote_table.py -v'

block table-change
sed -i 's/"N": 2990/"N": 3090/' shipquote/quote.py
run 'python -m pytest tests/test_quote_table.py -q --tb=line'
git checkout -q shipquote/quote.py

block seeds
run "python3 -c 'import random; random.seed(7); print(random.sample(range(100), 5))'"
run "python3 -c 'import random; random.seed(7); print(random.sample(range(100), 5))'"

block property
run 'python -m pytest tests/test_money_properties.py -v --hypothesis-show-statistics | grep -E "passed|examples|PASSED"'

block property-fail
python3 - <<'PY'
p = "shipquote/money.py"
s = open(p).read()
old = s[s.index("    base, rest = divmod(cents, parts)"):]
s = s.replace(old, "    each = round(cents / parts)\n    return [each] * (parts - 1) + [cents - each * (parts - 1)]\n")
open(p, "w").write(s)
PY
run 'git diff shipquote/money.py'
run 'python -m pytest tests/test_money_properties.py -q --hypothesis-seed=0 2>&1 | grep -E "^(Falsifying|test_|    [a-z]|E  |FAILED|[0-9]+ (failed|passed))"'
git checkout -q shipquote/money.py

block emails
run "grep -rhoE '[a-z]+@[a-z.]+' tests/ | sort | uniq -c"
