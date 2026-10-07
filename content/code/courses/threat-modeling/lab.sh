#!/usr/bin/env bash
# The workspace of the threat-modeling course: ~/tm, a Python virtual
# environment with pytm in it, and ~/tm/portal-model, the git repository where
# the threat model of Vereda's patient portal lives as files.
#
#   bash lab.sh reset      rebuild ~/tm/portal-model from nothing
#                          (the virtual environment is kept if it is there)
#   bash lab.sh reset N    the same, stopping after the Nth commit: the state
#                          of the repository when an earlier lesson was recorded
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
#     in full; what is here is what they print. model.py is the one file a
#     later lesson changes, and that change is console.patch, applied as its
#     own commit, so model.py itself stays as lesson 2 prints it. threats.csv
#     grows the same way: lesson 7 appends threats-from-abuse-cases.csv.

set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
TM=${TM:-$HOME/tm}
export TZ=America/Sao_Paulo

STOP=999
MADE=0
commit() {   # commit 'YYYY-MM-DD HH:MM' 'message', and stop if that was the last one asked for
  GIT_AUTHOR_DATE="$1:00 -0300" GIT_COMMITTER_DATE="$1:00 -0300" \
    git -c user.name=ana -c user.email=ana@vereda.example commit -q -m "$2"
  MADE=$((MADE + 1))
  if [ "$MADE" -ge "$STOP" ]; then exit 0; fi
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
  printf '__pycache__/\nmodel.json\n' > .gitignore
  git add .gitignore
  add model.py flows.py
  commit '2026-09-01 10:00' 'Draw the portal as a data flow diagram'
  add findings.py
  commit '2026-09-03 15:20' 'Summarise what pytm finds'
  add threats.csv
  commit '2026-09-03 17:05' 'List the threats found with STRIDE'
  add tree.py
  commit '2026-09-08 11:30' 'Model one goal as an attack tree'
  add surface.py
  commit '2026-09-10 09:40' 'List the entry and exit points'
  git apply "$here/lab/console.patch" && git add model.py
  commit '2026-09-10 10:15' 'Draw the console as it is: reachable from the internet'
  cat "$here/lab/threats-from-abuse-cases.csv" >> threats.csv && git add threats.csv
  commit '2026-09-14 16:00' 'Add the threats the abuse cases found'
  add requirements.csv trace.py
  commit '2026-09-17 14:30' 'Write a requirement for each threat'
  add risks.csv risk.py
  commit '2026-09-22 10:00' 'Estimate the expected loss of the larger risks'
  add fair.py matrix.py
  commit '2026-09-24 15:00' 'Simulate the ranges, and compare with a matrix'
  add controls.csv prioritise.py
  commit '2026-09-29 11:00' 'Rank the controls by what they save'
  add decisions/DR-001-second-factor.md decisions/RA-001-crafted-pdf.md \
    decisions/RA-002-cancellation-record.md acceptances.py
  commit '2026-10-01 17:30' 'Record the first decisions'
  add mapping.csv crosswalk.py
  commit '2026-10-05 14:00' 'Map the controls to ISO 27001 and the NIST CSF'
}

case ${1:-} in
  reset) STOP=${2:-999}; reset ;;
  *) echo "usage: bash lab.sh reset [N]" >&2; exit 2 ;;
esac
