# Sourced by every lesson's captures.sh. It prints what ana typed in ~/gov
# and what came back, in the form the lessons quote.
#
#   on 'COMMAND'        the prompt, the command, and its output
#   put FILE <<'EOF'    a file ana wrote in ~/gov (shown with `code`)
#   code NAME FILE      a marker line, then the file as it is
#   block NAME          a marker line; the lessons are copied block by block
#   quiet 'COMMAND'     run as ana and print nothing (setting a scene the
#                       lesson describes rather than shows)
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/gov$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "cat > '$1'"; }
code() { printf '##### %s\n' "$1"; lab exec "cat '$2'"; }
block() { printf '##### %s\n' "$1"; }
quiet() { lab exec "$*" >/dev/null 2>&1 || true; }
exec 9>/var/tmp/gov-capture.lock; flock 9
