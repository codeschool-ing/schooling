# Sourced by every lesson's captures.sh: the helpers that turn a script into
# the terminal sessions a lesson quotes. The author's, like lab.sh.
#
#   on 'COMMAND'      what ana typed in ~/agents, and what it printed
#   on_tty 'COMMAND'  the same, for a program that draws for a terminal; its
#                     control codes are removed, leaving what a terminal shows
#   put PATH          a file ana wrote, from stdin. lab/shown.py checks that a
#                     lesson shows it whole before it is written
#   say 'COMMAND'     a command ana typed that changes her shell, such as an
#                     export: printed as typed, and kept for every later line
#   block NAME        a marker in the output, never in a lesson
#
# One capture at a time: every run rebuilds ~/agents from nothing.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-$(dirname "${BASH_SOURCE[0]}")/../lab.sh}
SHOWN=${SHOWN:-$(dirname "${BASH_SOURCE[0]}")/shown.py}
SHELL_STATE=""
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/agents$ %s\n' "$*"; lab exec "$SHELL_STATE $*" < /dev/null 2>&1 || true; }
on_tty() {
  printf 'ana@lab:~/agents$ %s\n' "$*"
  lab exec "$SHELL_STATE $*" < /dev/null 2>&1 | python3 -c '
import re, sys
t = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]|[⠀-⣿] ?", "", sys.stdin.read())
print(t.strip("\n"))' || true
}
say() { printf 'ana@lab:~/agents$ %s\n' "$*"; SHELL_STATE="$SHELL_STATE $*;"; }
put() {
  local t; t=$(mktemp); cat > "$t"
  python3 "$SHOWN" "$t" || { rm -f "$t"; exit 1; }
  lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'" < "$t"; rm -f "$t"
}
block() { printf '##### %s\n' "$1"; }
# The recorder, started in the background as lesson 1 shows; stopped by `quiet`.
recorder() { on 'python recorder.py &'; sleep 1; }
quiet() { lab exec 'pkill -u ana -f "python (recorder|standin)[.]py"' || true; }
exec 9>/var/tmp/agents-capture.lock; flock 9
trap quiet EXIT
lab reset >/dev/null
