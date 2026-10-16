# Sourced by lab.sh and by the lessons' captures.sh. Not for the student, who
# has none of it.
#
# THE PROGRAMS A CAPTURE RUNS ARE READ OUT OF THE LESSON THAT SHOWS THEM, so the
# two cannot drift apart: there is no second copy of prices.py to edit.
#
#   example FILE NAME DEST   writes DEST from the schooling-example in FILE whose
#                            "file" is NAME: its code parts, in order
#   fence FILE N             prints the Nth ```sh fence of FILE (counted from 1)
#   file_fence FILE NAME     prints the fence that follows the line `NAME:` in
#                            FILE, for a small file shown whole in a lesson
#   run CMD                  prints the prompt and CMD, then runs CMD; what the
#                            terminal would show is what is printed, so a line a
#                            progress meter rewrites with \r keeps its last state
#   block NAME               a marker line the author copies transcripts by

AWS_DATA_COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSONS="$AWS_DATA_COURSE/lessons"

example() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
blocks = re.findall(r'^```schooling-example\n(.*?)\n```$', text, re.S | re.M)
found = [b for b in (json.loads(x) for x in blocks) if b.get('file') == sys.argv[2]]
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one example for {sys.argv[2]}, found {len(found)}')
open(sys.argv[3], 'w').write(''.join(p['code'] for p in found[0]['parts']))
PY
}

fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
fences = re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
n = int(sys.argv[2])
if not 1 <= n <= len(fences):
    sys.exit(f'{sys.argv[1]}: no sh fence number {n} (there are {len(fences)})')
sys.stdout.write(fences[n - 1])
PY
}

file_fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r'`' + re.escape(sys.argv[2]) + r'`:\n\n```[a-z]*\n(.*?)^```$', text, re.S | re.M)
if not m:
    sys.exit(f'{sys.argv[1]}: no fence introduced by `{sys.argv[2]}`:')
sys.stdout.write(m.group(1))
PY
}

PROMPT_DIR=${PROMPT_DIR:-'~/aws'}
run() {
  printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"
  bash -c "$*" 2>&1 | sed 's/.*\r//' || true
}
block() { printf '##### %s\n' "$1"; }

# moto as the student runs it, in its own terminal. Restarting it is how a
# capture starts from an empty AWS, and the arguments are environment
# assignments for the server (INITIAL_NO_AUTH_ACTION_COUNT=… in lesson 4).
moto_start() {
  ( cd "$HOME/aws" && env "$@" setsid bash -c 'echo $$ > "$HOME/.moto.pid"; exec "$HOME/aws/venv/bin/moto_server" -p 4567' \
      > "$HOME/.moto.log" 2>&1 < /dev/null & )
  for _ in $(seq 80); do
    curl -s -o /dev/null http://127.0.0.1:4567/moto-api/ && return 0
    sleep 0.25
  done
  echo "moto did not start:"; cat "$HOME/.moto.log"; return 1
}
moto_stop() {
  [ -f "$HOME/.moto.pid" ] || return 0
  kill "$(cat "$HOME/.moto.pid")" 2>/dev/null
  for _ in $(seq 40); do curl -s -o /dev/null http://127.0.0.1:4567/ || break; sleep 0.25; done
  rm -f "$HOME/.moto.pid"
}
