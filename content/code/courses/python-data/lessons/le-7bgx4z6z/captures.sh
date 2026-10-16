#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of python-data, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, by ../../lab/fill.py, and
# `fill.py --check` holds the lesson to it. The lesson's cells are run by
# `../../lab.sh cells`.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l11.txt
#   python3 ../../lab/fill.py --check . /tmp/l11.txt
#
# What is STAGED rather than typed: cow.py, written from the-old-warning.md's
# own fence, and `oldpandas`, the second folder of lesson 3 with pandas 2.2.3,
# made here the way that lesson makes it if it is not already there.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PIP_DISABLE_PIP_VERSION_CHECK=1
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf '(.venv) ana@lab:~/pydata$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
fence() { python3 - "$HERE/$1" "$2" "$3" <<'PY'
import re, sys
text, lang, n = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2], int(sys.argv[3])
sys.stdout.write(re.findall(r"^```" + lang + r"\n(.*?)^```$", text, re.S | re.M)[n])
PY
}
lab reset >/dev/null
fence the-old-warning.md py 0 | lab exec 'cat > cow.py'
lab raw '[ -x oldpandas/.venv/bin/python ] || { mkdir -p oldpandas && cd oldpandas && python3 -m venv .venv && .venv/bin/pip install -q pandas==2.2.3 ipykernel; }' >/dev/null 2>&1

block cow2
printf '(.venv) ana@lab:~/pydata$ %s\n' '~/oldpandas/.venv/bin/python cow.py'
lab exec '~/oldpandas/.venv/bin/python cow.py 2>&1' || true
block cow3
on python cow.py
