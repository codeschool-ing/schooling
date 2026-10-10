# Sourced by every lesson's capture script. It prints each transcript as a
# block headed `##### name`; the lesson pastes the block between the markers.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lab.sh"
FENCE="$(dirname "$LAB_SH")/lab/fence.py"
lab() { bash "$LAB_SH" "$@"; }
block() { printf '##### %s\n' "$1"; }
# on CMD: one command typed at ana's prompt, in a shell of its own
on() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# shell: every line on stdin typed into ONE shell, so `$?`, `cd` and variables
# carry from one line to the next as they do for a person at a prompt
shell() {
  local script='__s=0'$'\n' l
  while IFS= read -r l; do
    script+="printf 'ana@vm:%s\$ %s\n' \"\${PWD/#\$HOME/\~}\" $(printf %q "$l"); (exit \$__s); { $l
} 2>&1; __s=\$?"$'\n'
  done
  lab exec "$script" || true
}
# session DB [ARGS]: lines on stdin typed at an interactive psql
session() { lab psql "$@"; }
# extract FILE.md PREFIX: a block the lesson shows, as the student copies it
extract() { python3 "$FENCE" "$@"; }
exec 9>/var/tmp/db-reliability-capture.lock; flock 9
