# Sourced by every lesson's captures.sh. It is the author's, like lab.sh.
#
#   run DIR 'command'     print ana's prompt in DIR and the command, then run it
#                         there and print what it printed
#   quiet DIR 'command'   run it and print nothing: a step the lesson describes
#                         in prose, or one it already showed
#   block NAME            start a named block: lab/fill.py pastes each block
#                         into the fence of the lesson that holds it
#   put MD FILE DEST      write the listing of FILE that the lesson's MD shows
#                         (lab/extract.py) to DEST: the file the lesson prints
#                         is the file the capture runs. MD may be another
#                         lesson's, as ../le-xxxxxxxx/section.md
#   serve DIR PORT 'cmd'  start a server in the background in DIR and wait for
#                         PORT to answer; `unserve` stops it (and EXIT does)
#
# Every lesson is recorded in a home of its own (lab.sh says why), and its
# captures start from an EMPTY home: what the lesson needs from an earlier one
# is put there with `put`, and the script's header says so.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
MF_LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MF_COURSE=$(dirname "$MF_LAB")
LESSON=$(cd "$(dirname "$0")" && pwd)
LID=$(basename "$LESSON")
LAB() { bash "$MF_COURSE/lab.sh" "$@"; }
LAB reset "$LID"
H=$(LAB path "$LID")

shown() { local d=$1; d=${d/#\/home\/ana/\~}; printf '%s' "$d"; }
run() {
  local dir=$1; shift
  printf 'ana@dev:%s$ %s\n' "$(shown "$dir")" "$*"
  local out
  out=$(LAB as "$LID" "${RUNENV:+$RUNENV; }cd $dir && $*" 2>&1; printf x)
  out=${out%x}
  printf '%s' "$out"
  [ -z "$out" ] || [ "${out: -1}" = $'\n' ] || printf '\n'
  return 0
}
quiet() { local dir=$1; shift; LAB as "$LID" "cd $dir && $*" >/dev/null 2>&1; return 0; }
block() { printf '##### %s\n' "$1"; }
put() {   # put MD FILE DEST
  local md=$1 file=$2 dest=$3
  local real=$H${dest#/home/ana}
  mkdir -p "$(dirname "$real")"
  python3 "$MF_LAB/extract.py" "$LESSON/$md" "$file" > "$real" ||
    { echo "put: no listing of $file in $md" >&2; exit 1; }
  chown -R ana:ana "$H"
}
SERVER=
serve() { # serve DIR PORT 'command'
  # The server runs under its own `lab.sh as`, in the background, in a session
  # of its own: a server started inside a `run` dies with that run's PID
  # namespace the moment the command returns. unserve kills the session.
  local dir=$1 port=$2; shift 2
  setsid bash "$MF_COURSE/lab.sh" as "$LID" "cd $dir && exec $*" </dev/null >"$H/.serve.log" 2>&1 &
  SERVER=$!
  for _ in $(seq 100); do
    curl -s --noproxy '*' -o /dev/null "http://127.0.0.1:$port/" && return 0
    sleep 0.2
  done
  echo "serve: nothing answered on port $port" >&2; cat "$H/.serve.log" >&2; exit 1
}
unserve() {
  [ -n "$SERVER" ] || return 0
  kill -- -"$SERVER" 2>/dev/null; wait "$SERVER" 2>/dev/null; rm -f "$H/.serve.log"
  SERVER=; sleep 0.5
}
trap unserve EXIT
