# Sourced by every captures.sh of go-back. It defines what a capture script
# can do, so that every lesson types and prints the same way.
#
#   on DIR 'cmd'        print ana's prompt and the command, then run it and
#                       print everything it wrote, stdout and stderr together
#   quiet DIR 'cmd'     run it and print nothing (a staged step)
#   put DIR/FILE        write stdin to ~ana/DIR/FILE
#   show FILE.md PREFIX DIR/FILE
#                       write the block of a lesson's .md whose first line
#                       starts with PREFIX into ~ana/DIR/FILE: the file the
#                       student copies is the file that runs
#   project N DIR       the boxoffice project as lesson N leaves it, in ~ana/DIR
#   serve DIR 'cmd'     start cmd in the background, as ana, in its own process
#                       group, with its output in ~ana/DIR/.server.log; waits
#                       until something answers on $PORT (default 8080)
#   stop                send SIGTERM to that process group and wait for it
#   block NAME          a separator in the output, for the author to find
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

LAB_SH=${LAB_SH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lab.sh}
FENCE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/fence.py
PORT=${PORT:-8080}
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
put() { lab put "$1"; }
show() { python3 "$FENCE" "$1" "$2" | lab put "$3"; }
project() { lab project "$1" "$2"; }
block() { printf '\n##### %s\n' "$1"; }

SERVER_PID=
serve() {
  local d=$1 cmd=$2
  setsid bash "$LAB_SH" exec "$d" "exec $cmd > ~/'$d'/.server.log 2>&1" </dev/null >/dev/null 2>&1 &
  SERVER_PID=$!
  local i
  for i in $(seq 1 300); do
    if (exec 3<>/dev/tcp/127.0.0.1/"$PORT") 2>/dev/null; then return 0; fi
    sleep 0.2
  done
  echo "serve: nothing answered on $PORT" >&2
}
stop() {
  [ -n "$SERVER_PID" ] || return 0
  kill -TERM -- -"$SERVER_PID" 2>/dev/null || true
  local i
  for i in $(seq 1 100); do
    kill -0 -- -"$SERVER_PID" 2>/dev/null || break
    sleep 0.1
  done
  kill -KILL -- -"$SERVER_PID" 2>/dev/null || true
  SERVER_PID=
}
trap stop EXIT
