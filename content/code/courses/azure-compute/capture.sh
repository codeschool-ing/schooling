# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes. Not for the student, who has none of it.
#
# A captures.sh re-runs itself inside a fresh lab (lab.sh run): an empty
# ~/azure, and the environment the lesson's terminal has.
# Then:
#
#   run 'command'        print ana's prompt and the command, then run it and
#                        print everything it wrote, stdout and stderr together
#   quiet 'command'      run without showing: the lab's own housekeeping, which
#                        the script's header says is staged
#   put FILE <<'EOF'     a file ana wrote, from stdin, printed between "file:"
#                        markers so the lesson quotes the file that was used
#   block NAME           a marker between transcripts, never quoted
#   from_lesson MD PATH  the fenced block of MD that holds the line "# PATH",
#                        or "// PATH" in a language whose comments start so
#   from_example MD FILE the code of the schooling-example of MD whose file is
#                        FILE, its parts in order
#
# A file a lesson shows the student is taken from the lesson rather than kept
# twice, so what a capture runs and what the student reads cannot drift apart.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -z "${IN_LAB:-}" ]; then
  export IN_LAB=1
  exec bash "$COURSE/lab.sh" run env IN_LAB=1 LAB_PROXY="${HTTPS_PROXY:-}" bash "$(realpath "$0")" "$@"
fi
cd /home/ana/azure || exit 1

prompt() {
  local here=${PWD/#\/home\/ana/\~}
  printf 'ana@laptop:%s$ %s\n' "$here" "$1"
}
run() {
  prompt "$1"
  eval "$1" 2>&1 </dev/null
  return 0
}
quiet() { eval "$1" >/dev/null 2>&1 </dev/null || true; }
put() {
  mkdir -p "$(dirname "$1")" && cat > "$1"
  printf '##### file:%s\n' "${PWD/#\/home\/ana/\~}/$1"; cat "$1"; printf '##### end-file\n'
}
block() { printf '##### %s\n' "$1"; }

from_lesson() {
  awk -v want="# $2" -v alt="// $2" '
    /^```/ { if (open) { if (hit) { printf "%s", buf; found = 1; exit } open = 0; next }
             open = 1; buf = ""; hit = 0; next }
    open   { buf = buf $0 "\n"; if ($0 == want || index($0, want ":") == 1 || $0 == alt) hit = 1 }
    END    { exit found ? 0 : 1 }' "$1" || { echo "from_lesson: no block with \"# $2\" in $1" >&2; exit 1; }
}

from_example() {
  python3 - "$1" "$2" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
blocks = re.findall(r'^```schooling-example\n(.*?)\n```$', text, re.S | re.M)
found = [b for b in (json.loads(x) for x in blocks) if b.get('file') == sys.argv[2]]
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one example for {sys.argv[2]}, found {len(found)}')
sys.stdout.write(''.join(p['code'] for p in found[0]['parts']))
PY
}
