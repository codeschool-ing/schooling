# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes.
#
# A captures.sh re-runs itself inside a fresh lab (lab.sh run): its own empty
# moto on localhost:4566, its own /home/ana, ana's environment. Then:
#
#   run 'command'        print ana's prompt and the command, then run it and
#                        print everything it wrote, stdout and stderr together
#   answer 'command' yes the same for a command that asks a question, with the
#                        answer typed at it: the answer is shown after the
#                        question, where a terminal would have echoed it
#   quiet 'command'      run without showing: the lab's own housekeeping
#   put FILE <<'EOF'     a file ana wrote, from stdin. Its content is shown in
#                        the lesson as a fence of its own, and is printed here
#                        between "file:" markers so it is quoted from the run
#   block NAME           a marker between transcripts, never quoted
#
# Two things differ from a terminal, both on purpose. Terraform's colour codes
# are stripped, because a fence has no colours. And a prompt is printed by
# this script rather than by a shell, from the same directory the command ran
# in.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -z "${IN_LAB:-}" ]; then
  export IN_LAB=1
  exec bash "$COURSE/lab.sh" run env IN_LAB=1 LAB_HOSTS="${LAB_HOSTS:-}" bash "$(realpath "$0")" "$@"
fi
cd /home/ana || exit 1
HOST=${HOST:-laptop}

decolour() { sed -u 's/\x1b\[[0-9;]*m//g'; }
prompt() {
  local here=${PWD/#\/home\/ana/\~}
  printf 'ana@%s:%s$ %s\n' "$HOST" "$here" "$1"
}
run() {
  prompt "$1"
  eval "$1" 2>&1 </dev/null | decolour
  return 0
}
answer() {
  prompt "$1"
  printf '%s\n' "$2" | eval "$1" 2>&1 | decolour | sed -u "s/^\(  Enter a value: \)\$/\1$2/; t; s/^\(  Enter a value: \)\(.\)/\1$2\n\2/"
  return 0
}
quiet() { eval "$1" >/dev/null 2>&1 </dev/null || true; }
put() { # also printed between file markers, so the lesson quotes the file
  # that was used rather than a copy of it
  mkdir -p "$(dirname "$1")" && cat > "$1"
  printf '##### file:%s\n' "${PWD/#\/home\/ana/\~}/$1"; cat "$1"; printf '##### end-file\n'
}
block() { printf '##### %s\n' "$1"; }
