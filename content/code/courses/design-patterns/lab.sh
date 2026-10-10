#!/usr/bin/env bash
# The author's lab for design-patterns: what turns a lesson's program into the
# file a capture runs, and the prompt a transcript is printed under.
#
# THE STUDENT NEVER SEES THIS FILE (C-40). The course needs one thing on the
# student's machine, Python 3.12 or newer, and lesson 1 section `the-lab` says
# how to have it in three ways. Every program the student runs is shown whole
# in a lesson; this script only lifts those programs back OUT of the lesson, so
# the file a capture runs is the very block the student copies and cannot
# drift from it.
#
#   bash lab.sh extract MD NAME [K] [DIR]  write the K-th block of MD that is
#                                          the file NAME (default: the last) to
#                                          DIR/NAME (default: the current dir)
#   bash lab.sh files MD                   list the file blocks MD holds
#   source lab.sh                          and then, in a captures.sh:
#       at DIR            cd to ~/patterns/DIR, creating it
#       put MD NAME [K]   extract a block into the current directory
#       run CMD...        print the prompt and CMD, then run it, 2>&1
#       block NAME        start a named block of output (##### NAME)
#
# WHAT A FILE BLOCK IS. An ordinary fence labelled `python` whose FIRST line is
# a comment naming the file, `# shapes.py`, or a `schooling-example` whose
# `file` is the name. The copy button of an example joins its parts with one
# newline, and so does this, so what is extracted is what the student pastes.
#
# The transcripts are printed as Ana's, on a machine called laptop, from
# /home/ana/patterns: run as root with HOME=/home/ana. TZ=America/Sao_Paulo and
# PYTHONHASHSEED=0, so that a set printed in a transcript prints in the same
# order on every run.
#
# THE MACHINE IS A STOCK UBUNTU 24.04 AS THE STUDENT HAS IT, which this sandbox
# is not: it carries a second Python, a `python` command and a dozen tools a
# fresh install does not. So `run` executes with PATH holding one directory,
# /opt/dp-lab/bin, built below with `python3` pointing at Ubuntu's own 3.12.3
# and the handful of ordinary commands the lessons type. A command the student
# would not have answers `command not found` here too, which is the point.
set -uo pipefail

_lab_py() {
python3 - "$@" <<'PY'
import json, re, sys
cmd, md = sys.argv[1], sys.argv[2]
text = open(md, encoding='utf-8').read()
blocks = []
for m in re.finditer(r'^```([\w-]*)\n(.*?)^```$', text, re.S | re.M):
    lang, body = m.group(1), m.group(2)
    if lang == 'python':
        first = body.split('\n', 1)[0]
        f = re.fullmatch(r'# ([\w./-]+\.py)', first)
        if f:
            blocks.append((f.group(1), body))
    elif lang == 'schooling-example':
        ex = json.loads(body)
        if ex.get('file'):
            blocks.append((ex['file'], '\n'.join(p['code'] for p in ex['parts']) + '\n'))
if cmd == 'files':
    for name, _ in blocks:
        print(name)
    sys.exit(0)
name = sys.argv[3]
k = int(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4] else 0
mine = [b for n, b in blocks if n == name]
if not mine:
    sys.exit(f'{md}: no block is the file {name}')
if k > len(mine):
    sys.exit(f'{md}: {name} appears {len(mine)} times, not {k}')
sys.stdout.write(mine[k - 1] if k else mine[-1])
PY
}

case "${1:-}" in
  extract)
    md=$2 name=$3 k=${4:-} dir=${5:-.}
    mkdir -p "$dir/$(dirname "$name")"
    _lab_py extract "$md" "$name" "$k" > "$dir/$name.tmp" && mv "$dir/$name.tmp" "$dir/$name" || { rm -f "$dir/$name.tmp"; exit 1; }
    ;;
  files)
    _lab_py files "$2" ;;
  '')
    # sourced
    export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana PYTHONHASHSEED=0
    export PYTHONDONTWRITEBYTECODE=1
    LAB_SELF=${BASH_SOURCE[0]}
    at() { mkdir -p "$HOME/patterns/$1" && cd "$HOME/patterns/$1" || exit 1; }
    put() { bash "$LAB_SELF" extract "$1" "$2" "${3:-}" . || exit 1; }
    block() { printf '##### %s\n' "$1"; }
    LABBIN=/opt/dp-lab/bin
    if [ ! -x "$LABBIN/python3" ]; then
      mkdir -p "$LABBIN"
      ln -sf /usr/bin/python3.12 "$LABBIN/python3"
      for t in bash sh ls cat mkdir rm cp mv echo printf sed grep head tail wc diff sort env which true false sleep nl; do
        ln -sf "$(command -v $t)" "$LABBIN/$t"
      done
    fi
    run() {
      local here=${PWD/#$HOME/\~}
      printf 'ana@laptop:%s$ %s\n' "$here" "$*"
      PATH=$LABBIN bash -c "$*" 2>&1
    }
    ;;
  *) echo "usage: see the header of $0" >&2; exit 2 ;;
esac
