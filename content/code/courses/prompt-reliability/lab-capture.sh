# Sourced by each lesson's captures.sh, never run on its own:
#
#   LESSON=2; . "$here/../../lab-capture.sh"
#
# It builds ~/triage as a student has it after lesson $LESSON, under its own
# HOME so nothing of yours is touched, with every file read out of the lessons'
# own fences by `lab.sh files`. It checks that Ollama answers and the model is
# pulled, puts `pl` on the PATH as the alias the-harness.md defines, and gives
# the script `on` (print a command after the prompt, then run it) and `block`.
# Python is 3.12, Ubuntu 24.04's.
set -uo pipefail
course=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat GIT_PAGER=cat COLUMNS=100 PYTHONDONTWRITEBYTECODE=1 TERM=dumb
REAL_HOME=$HOME
export HOME=${LAB_HOME:-/var/tmp/prompt-reliability}
rm -rf "$HOME/triage"
mkdir -p "$HOME/bin" "$HOME/triage/runs"
bash "$course/lab.sh" check || exit 1
bash "$course/lab.sh" files "$LESSON" 2>/dev/null || exit 1
ln -sf /usr/bin/python3.12 "$HOME/bin/python3"
printf '#!/bin/sh\nexec python3 "$HOME/triage/pl.py" "$@"\n' > "$HOME/bin/pl"
chmod +x "$HOME/bin/pl"
export PATH=$HOME/bin:$PATH
cd "$HOME/triage"
on() { printf 'ana@lab:~/triage$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
# Runs a command without printing it: what a transcript needs to exist but the
# lesson does not show, such as a run an earlier lesson already showed.
quiet() { bash -c "$*" >/dev/null 2>&1; }
