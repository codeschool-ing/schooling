# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes.
#
# A captures.sh re-runs itself inside the lab (lab.sh run): a clean daemon, an
# empty /home/ana, ana's environment, and a lock, because every lesson uses the
# same container names. Then:
#
#   run 'command'          print ana's prompt and the command, run it, and
#                          print everything it wrote, stdout and stderr together
#   quiet 'command'        run without showing: the lab's own housekeeping
#   session 'command' <<'EOF'
#                          an interactive client (mongosh, redis-cli, cqlsh)
#                          started by `command`, and the lines typed at it,
#                          through lab/session.py
#   put FILE <<'EOF'       a file ana wrote, from stdin, printed between
#                          "file:" markers so the lesson quotes the file used
#   staged FILE <<'EOF'    a file written without showing it, because a lesson
#                          shows it whole; refused unless some lesson does
#   from MD FIRSTLINE      print the fence of lesson file MD (relative to the
#                          lesson) whose first line is FIRSTLINE: what a
#                          lesson tells the student to type or save
#   example MD FILE        print the program the annotated example naming FILE
#                          in MD adds up to
#   block NAME             a marker between transcripts, never quoted
#   ready_mongo NAME, ready_redis NAME, ready_cassandra NAME [NODES]
#                          wait, silently, until the server in container NAME
#                          answers (and, for Cassandra, until NODES nodes are
#                          UN) — the waiting a student does by trying again
#
# A prompt is printed by this script rather than by a shell, from the
# directory the command ran in, and a command runs with no terminal attached.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON=$(cd "$(dirname "$0")" && pwd)
if [ -z "${IN_LAB:-}" ]; then
  exec sudo bash "$COURSE/lab.sh" run bash "$(realpath "$0")" "$@"
fi
cd /home/ana || exit 1

prompt() {
  local rc=$? here=${PWD/#\/home\/ana/\~}
  printf 'ana@vm:%s$ %s\n' "$here" "$1"
  return $rc
}
run() {
  prompt "$1"
  eval "$1" 2>&1 </dev/null
}
quiet() { eval "$1" >/dev/null 2>&1 </dev/null || true; }
session() {
  prompt "$1"
  # shellcheck disable=SC2086
  eval "python3 \"$COURSE/lab/session.py\" $1"
}
put() {
  mkdir -p "$(dirname "$1")" && cat > "$1"
  printf '##### file:%s\n' "${PWD/#\/home\/ana/\~}/$1"; cat "$1"; printf '##### end-file\n'
}
block() { printf '##### %s\n' "$1"; }
staged() {
  local text; text=$(cat; printf x); text=${text%x}
  printf '%s' "$text" | python3 "$COURSE/lab/fences.py" has "$COURSE" || exit 1
  mkdir -p "$(dirname "$1")" && printf '%s' "$text" > "$1"
}
from() { python3 "$COURSE/lab/fences.py" block "$LESSON/$1" "$2"; }
example() { python3 "$COURSE/lab/fences.py" example "$LESSON/$1" "$2"; }

ready_mongo() {
  local i
  for i in $(seq 120); do
    docker exec "$1" mongosh --quiet --eval 'db.runCommand({ping: 1}).ok' >/dev/null 2>&1 && return 0
    sleep 1
  done
  echo "ready_mongo: $1 never answered" >&2; exit 1
}
ready_redis() {
  local i
  for i in $(seq 60); do
    [ "$(docker exec "$1" redis-cli ping 2>/dev/null)" = PONG ] && return 0
    sleep 1
  done
  echo "ready_redis: $1 never answered" >&2; exit 1
}
ready_cassandra() {
  local i n=${2:-1}
  for i in $(seq 120); do
    if docker exec "$1" cqlsh -e 'SELECT now() FROM system.local' >/dev/null 2>&1 &&
       [ "$(docker exec "$1" nodetool status 2>/dev/null | grep -c '^UN')" -ge "$n" ]; then
      return 0
    fi
    sleep 5
  done
  echo "ready_cassandra: $1 never had $n nodes up" >&2; exit 1
}
