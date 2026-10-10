#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of python-data, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, by ../../lab/fill.py, and
# `fill.py --check` holds the lesson to it. The lesson's cells are run by
# `../../lab.sh cells`, which holds them the same way.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l04.txt
#   python3 ../../lab/fill.py --check . /tmp/l04.txt
#
# What is STAGED rather than typed: promote.py, written from numpy-2.md's own
# fence, and `oldnumpy`, a second folder with NumPy 1.26.4, made the way
# lesson 3 makes `oldpandas`.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PIP_DISABLE_PIP_VERSION_CHECK=1
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf '(.venv) ana@lab:~/pydata$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
at() { local dir=$1; shift; printf '(.venv) ana@lab:~/%s$ %s\n' "$dir" "$*"; lab raw "cd $dir && source .venv/bin/activate && $*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
fence() { python3 - "$HERE/$1" "$2" "$3" <<'PY'
import re, sys
text, lang, n = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2], int(sys.argv[3])
sys.stdout.write(re.findall(r"^```" + lang + r"\n(.*?)^```$", text, re.S | re.M)[n])
PY
}
lab reset >/dev/null
fence numpy-2.md py 0 | lab exec 'cat > promote.py'
lab raw 'rm -rf oldnumpy && mkdir oldnumpy && cd oldnumpy && python3 -m venv .venv && .venv/bin/pip install -q numpy==1.26.4' >/dev/null 2>&1

block numpy1
at oldnumpy 'python ~/pydata/promote.py'
on python promote.py
