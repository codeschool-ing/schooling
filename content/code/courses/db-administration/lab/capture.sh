# Helpers for the lessons' captures.sh. Sourced, never run.
#
#   on 'cmd'          print the prompt and the command, then run it as ana
#   onroot 'cmd'      the same as root, with root's prompt
#   session DB        an interactive psql as ana; stdin lines are typed at it
#   block NAME        a marker between transcripts, so a lesson's blocks can
#                     be found in the output
#   fence FILE PREFIX print the fenced block of lessons/FILE starting PREFIX
#
# The prompt is ana@db:DIR$, as the server lesson 3 builds is called db.
set -uo pipefail
LAB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
lab() { bash "$LAB_DIR/lab.sh" "$@"; }
on() { printf 'ana@db:~$ %s\n' "$*"; lab as "$*" </dev/null 2>&1 || true; }
onroot() { printf 'root@db:~# %s\n' "$*"; lab root "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
fence() { python3 "$LAB_DIR/lab/fence.py" "$LAB_DIR/lessons/$1" "$2"; }
