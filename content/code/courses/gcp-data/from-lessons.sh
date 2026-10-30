# Sourced by lab.sh and by the lessons' captures.sh. Not for the student, who
# has none of it.
#
# THE PROGRAMS A CAPTURE RUNS ARE READ OUT OF THE LESSON THAT SHOWS THEM, so the
# two cannot drift apart: there is no second copy of a program to edit.
#
#   example FILE NAME DEST   writes DEST from the schooling-example in FILE whose
#                            "file" is NAME: its code parts, in order
#   fence FILE N             prints the Nth ```sh fence of FILE (counted from 1)
#   file_fence FILE NAME     prints the fence that follows the line `NAME`: in
#                            FILE, for a small file shown whole in a lesson
#   run CMD                  prints the prompt and CMD, then runs CMD; what the
#                            terminal would show is what is printed, so a line a
#                            progress meter rewrites with \r keeps its last state
#   block NAME               a marker line the author copies transcripts by
#   emu_start NAME / emu_stop NAME
#                            an emulator as the student runs it, in a terminal of
#                            its own: gcs, pubsub, firestore, bigtable, spanner.
#                            Restarting one is how a capture starts from empty.

GCP_DATA_COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSONS="$GCP_DATA_COURSE/lessons"
LAB_MD="$LESSONS/le-rba8jsay/the-lab.md"

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

PROMPT_DIR=${PROMPT_DIR:-'~/gcp'}
run() {
  printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"
  bash -c "$*" 2>&1 | sed 's/.*\r//' || true
}
block() { printf '##### %s\n' "$1"; }

# The command each emulator is started with is the one the lessons give; the
# fake-gcs-server line is read out of the-lab.md's fifth fence.
emu_cmd() {
  case "$1" in
    gcs) fence "$LAB_MD" 5 | grep '^fake-gcs-server' ;;
    pubsub) echo 'gcloud beta emulators pubsub start --project=planner-dev --host-port=localhost:8085' ;;
    firestore) echo 'gcloud emulators firestore start --host-port=localhost:8080' ;;
    bigtable) echo 'gcloud beta emulators bigtable start --host-port=localhost:8086' ;;
    spanner) echo 'gcloud emulators spanner start' ;;
    *) echo "unknown emulator $1" >&2; return 1 ;;
  esac
}
emu_port() {
  case "$1" in gcs) echo 4443 ;; pubsub) echo 8085 ;; firestore) echo 8080 ;;
    bigtable) echo 8086 ;; spanner) echo 9020 ;; esac
}
emu_start() {
  local name=$1; shift
  local cmd; cmd=$(emu_cmd "$name") || return 1
  ( cd "$HOME/gcp" && env "$@" setsid bash -c "echo \$\$ > \"\$HOME/.emu-$name.pid\"; exec $cmd" \
      > "$HOME/.emu-$name.log" 2>&1 < /dev/null & )
  local port; port=$(emu_port "$name")
  for _ in $(seq 240); do
    (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null && { sleep 0.5; return 0; }
    sleep 0.25
  done
  echo "$name did not start:"; cat "$HOME/.emu-$name.log"; return 1
}
emu_stop() {
  local name=$1 f="$HOME/.emu-$1.pid"
  [ -f "$f" ] || return 0
  # the emulators gcloud starts run as children of the shell; end the group
  kill -- -"$(cat "$f")" 2>/dev/null || kill "$(cat "$f")" 2>/dev/null
  local port; port=$(emu_port "$name")
  for _ in $(seq 40); do (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null || break; sleep 0.25; done
  rm -f "$f"
}
