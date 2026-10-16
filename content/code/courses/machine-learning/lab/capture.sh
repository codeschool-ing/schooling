# Sourced by every lesson's capture script. Not a program on its own.
#
#   block NAME        start the capture NAME; lab/paste.py puts it where the
#                     lesson says @@cap:NAME@@
#   sess <<'CMDS'     run the lines as ONE terminal session of ana's, each
#                     printed after the prompt it was typed at, so `cd` and
#                     `source` carry over from one line to the next
#   on 'COMMAND'      a session of one line
#   save MD FILE      the program the lesson shows as FILE, out of MD, into ~/ml
#   quiet 'COMMAND'   run as ana and show nothing: staging, never quoted
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lab() { bash "$LAB_DIR/lab.sh" "$@"; }
block() { printf '##### %s\n' "$1"; }
sess() {
  local script='exec 2>&1'$'\n'
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    script+="printf 'ana@lab:%s\$ %s\n' \"\$(dirs +0)\" $(printf '%q' "$line")"$'\n'
    script+="$line"$'\n'
  done
  lab exec "$script" || true
}
on() { printf '%s\n' "$1" | sess; }
save() { python3 "$LAB_DIR/lab/extract.py" "$1" "$2" | lab put "$2"; }
quiet() { lab exec "$1" >/dev/null 2>&1; }
