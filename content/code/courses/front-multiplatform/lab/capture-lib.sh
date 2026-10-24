# Sourced by every lesson's captures.sh. It is the author's, like lab.sh.
#
#   run DIR 'command'     print ana's prompt in DIR and the command, then run it
#                         there in the machine and print what it printed
#   quiet DIR 'command'   run it and print nothing: a step the lesson describes
#                         in prose, or one it already showed
#   block NAME            start a named block: lab/fill.py pastes each block
#                         into the fence of the lesson that holds it
#   put MD FILE DEST      write the listing of FILE that the lesson's MD shows
#                         (lab/extract.py) to DEST in the machine: the file the
#                         lesson prints is the file the capture runs
#   serve DIR PORT 'cmd'  start a server in the background in DIR and wait for
#                         PORT to answer; `unserve` stops it
#
# RUNENV, when set, is run silently before each command: what a staged step
# needs and the transcript does not show (a commit date, so hashes repeat).
# The machine is lab.sh's. /home/ana in these scripts is ana's home in it.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
FM_LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FM_COURSE=$(dirname "$FM_LAB")
LESSON=$(cd "$(dirname "$0")" && pwd)
M=${FM_MACHINE:-/var/lib/machines/fm}
LAB() { bash "$FM_COURSE/lab.sh" "$@"; }
LAB up

shown() { local d=$1; d=${d/#\/home\/ana/\~}; printf '%s' "$d"; }
run() {
  local dir=$1; shift
  printf 'ana@dev:%s$ %s\n' "$(shown "$dir")" "$*"
  local out
  out=$(LAB as "${RUNENV:+$RUNENV; }cd $dir && $*" 2>&1; printf x)
  out=${out%x}
  printf '%s' "$out"
  # A file with no newline at its end must not glue the next prompt to it.
  [ -z "$out" ] || [ "${out: -1}" = $'\n' ] || printf '\n'
  return 0
}
quiet() { local dir=$1; shift; LAB as "cd $dir && $*" >/dev/null 2>&1; return 0; }
block() { printf '##### %s\n' "$1"; }
put() {   # put MD FILE DEST
  local md=$1 file=$2 dest=$3
  mkdir -p "$M$(dirname "$dest")"
  python3 "$FM_LAB/extract.py" "$LESSON/$md" "$file" > "$M$dest" ||
    { echo "put: no listing of $file in $md" >&2; exit 1; }
  LAB root "chown -R ana:ana /home/ana"
}
SERVER=
serve() { # serve DIR PORT 'command'
  local dir=$1 port=$2; shift 2
  LAB as "cd $dir && { setsid bash -c 'echo \$\$ > /tmp/serve.pid; exec $*' </dev/null >/tmp/serve.log 2>&1 & }"
  for _ in $(seq 100); do
    curl -s -o /dev/null "http://127.0.0.1:$port/" && { SERVER=1; return 0; }
    sleep 0.2
  done
  echo "serve: nothing answered on port $port" >&2; LAB as 'cat /tmp/serve.log' >&2; exit 1
}
unserve() {
  [ -n "$SERVER" ] || return 0
  LAB as 'kill -- -$(cat /tmp/serve.pid) 2>/dev/null; rm -f /tmp/serve.pid'
  SERVER=; sleep 0.5
}
trap unserve EXIT
# commit DIR 'YYYY-MM-DD HH:MM' 'message': a commit with a fixed date, so the
# hashes repeat
commit() {
  LAB as "cd $1 && git add -A && GIT_AUTHOR_DATE='$2:00 -0300' GIT_COMMITTER_DATE='$2:00 -0300' git commit -q -m '$3'"
}
# Where a lesson starts. Lesson N's captures begin from the planner lesson N-1's
# captures left behind: `save_as N` keeps a copy of ana's projects when a
# lesson finishes, and `start_from N-1` puts that copy back. So the captures run
# IN ORDER the first time; after that any lesson can be run again on its own.
# What a student types to get from one lesson to the next is in the lessons.
SNAP=/var/lib/machines/fm-snapshots
PROJECTS="planner keep-awake planner-native planner_flutter planner-ionic planner-electron"
save_as() {
  mkdir -p $SNAP
  ( cd "$M/home/ana" && tar -cf "$SNAP/after-$1.tar" --exclude='*/src-tauri/target' --exclude='planner_flutter/build' --exclude='planner_flutter/.dart_tool' $(ls -d $PROJECTS 2>/dev/null) )
}
start_from() {
  [ -f "$SNAP/after-$1.tar" ] || { echo "no snapshot after lesson $1: run its captures first" >&2; exit 1; }
  ( cd "$M/home/ana" && rm -rf $PROJECTS && tar -xf "$SNAP/after-$1.tar" )
}
