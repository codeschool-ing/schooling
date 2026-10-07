#!/usr/bin/env bash
# The workspace of the threat-modeling course: ~/tm, a Python virtual
# environment with pytm in it, and ~/tm/portal-model, the git repository where
# the threat model of Vereda's patient portal lives as files.
#
#   bash lab.sh reset      rebuild ~/tm/portal-model from nothing
#                          (the virtual environment is kept if it is there)
#
# Lesson 1 builds this by hand, step by step, and every later lesson adds a
# file to it. This script is those steps written down, so that the captures in
# each lesson's captures.sh can be repeated; it is not something the student
# runs. It needs Python 3 with venv, git, and the network once, for pip.
#
# THE STORY. Vereda Fisioterapia is a small chain of physiotherapy clinics in
# São Paulo, the same invented company the cryptography course works for. Its
# patient portal books sessions, takes payment, stores the PDFs of exams that
# patients upload, and sends a reminder by SMS the day before. Every name,
# address and number here is invented.
#
# WHAT IS FIXED ON PURPOSE
#
#   - pytm is pinned to 1.4.0, the version every capture was recorded with.
#     Its threat library changes between releases, and a finding count from
#     another version is a different number.
#   - Every commit has a fixed author and date, so the history the lessons
#     show repeats byte for byte.
#   - The files come from lab/ beside this script. The lessons print each one
#     in full; what is here is what they print.

set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
TM=${TM:-$HOME/tm}
export TZ=America/Sao_Paulo

commit() {   # commit 'YYYY-MM-DD HH:MM' 'message'
  GIT_AUTHOR_DATE="$1:00 -0300" GIT_COMMITTER_DATE="$1:00 -0300" \
    git -c user.name=ana -c user.email=ana@vereda.example commit -q -m "$2"
}

add() {      # add FILE...: copy from lab/ into the repository and stage it
  for f in "$@"; do
    mkdir -p "$(dirname "$f")"
    cp "$here/lab/$f" "$f"
    git add "$f"
  done
}

reset() {
  mkdir -p "$TM"
  if [ ! -x "$TM/.venv/bin/python" ]; then
    python3 -m venv "$TM/.venv"
    "$TM/.venv/bin/pip" install -q --progress-bar off pytm==1.4.0
  fi
  rm -rf "$TM/portal-model"
  git init -q -b main "$TM/portal-model"
  cd "$TM/portal-model"
  printf '__pycache__/\nfindings.json\n' > .gitignore
  git add .gitignore
  add model.py
  commit '2026-09-01 10:00' 'Draw the portal as a data flow diagram'
  add findings.py
  commit '2026-09-03 15:20' 'Summarise what pytm finds'
}

case ${1:-} in
  reset) reset ;;
  *) echo "usage: bash lab.sh reset" >&2; exit 2 ;;
esac
