#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of python-data, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, by ../../lab/fill.py, and
# `fill.py --check` holds the lesson to it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l02.txt
#   python3 ../../lab/fill.py --check . /tmp/l02.txt
#
# What is STAGED rather than typed: order.ipynb is made from out-of-order.md's
# own `py` fences by ../../lab/order.py, which runs them in a kernel in the
# order the section narrates (first, third, second) and saves what each cell
# was left with, as JupyterLab does when Ana presses Ctrl+S. The git
# repository in outputs-in-git.md is ana's, with a name and an e-mail set for
# it, and its notebook is the lesson's fixed one.
#
# ANSI colour codes in a traceback are stripped: a terminal draws them as
# colours, and a page cannot.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf '(.venv) ana@lab:~/pydata$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null

lab exec "python '$HERE/../../lab/order.py' '$HERE/out-of-order.md' order.ipynb 0 1 2 1" >/dev/null 2>&1

block script
on "python -c 'import json; nb = json.load(open(\"order.ipynb\")); print(*[(c[\"execution_count\"], c[\"source\"][-1], c[\"outputs\"][-1][\"data\"][\"text/plain\"] if c[\"outputs\"] else []) for c in nb[\"cells\"]], sep=\"\\n\")'"

block execute
# The traceback is coloured for a terminal; the colours are taken out, as a
# terminal takes them out by drawing them.
on 'jupyter nbconvert --to notebook --execute --stdout order.ipynb > /dev/null 2> errors.txt; tail -n 15 errors.txt' | sed 's/\x1b\[[0-9;]*m//g'

lab exec "python '$HERE/../../lab/order.py' '$HERE/run-all.md' fixed.ipynb 0 1 2" >/dev/null 2>&1
block execute-ok
on jupyter execute fixed.ipynb

block inplace
on jupyter nbconvert --to notebook --execute --inplace fixed.ipynb
on "python -c 'import json; nb = json.load(open(\"fixed.ipynb\")); print(*[(c[\"execution_count\"], c[\"source\"][-1], c[\"outputs\"][-1][\"data\"][\"text/plain\"] if c[\"outputs\"] else []) for c in nb[\"cells\"]], sep=\"\\n\")'"

# --- outputs-in-git -------------------------------------------------------
lab exec 'git config --global user.name Ana && git config --global user.email ana@example.org && git config --global init.defaultBranch main'
lab exec "python '$HERE/../../lab/order.py' '$HERE/run-all.md' fixed.ipynb 0 1 2" >/dev/null 2>&1
block git-start
on git init -q
on "printf '.venv/\\n' > .gitignore"
on git add .gitignore fixed.ipynb
on 'git commit -qm "Wet days in 2025"'
# Ana reopens it the next day, runs the three cells, runs the last one twice
# more, and saves.
lab exec "python '$HERE/../../lab/order.py' --keep fixed.ipynb 0 1 2 2 2" >/dev/null 2>&1
block git-diff~
on git diff --stat
on git diff
block git-clear
on jupyter nbconvert --clear-output --inplace fixed.ipynb
on git diff --stat
