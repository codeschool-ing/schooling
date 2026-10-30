# Sourced by every lesson's captures.sh. It is the author's, like lab.sh.
#
#   run DIR 'command'     print ana's prompt in DIR and the command, then run it
#                         there as ana and print what it printed
#   quiet DIR 'command'   run it and print nothing: a step the lesson describes
#                         in prose, or one it already showed
#   block NAME            start a named block: lab/fill.py pastes each block
#                         into the fence of the lesson that holds it
#   put MD FILE DEST      write the listing of FILE that the lesson's MD shows
#                         (lab/extract.py) to DEST: the file the lesson prints
#                         is the file the capture runs
#   serve DIR PORT 'cmd'  start a server in the background in DIR and wait for
#                         PORT to answer; `unserve` stops it. One server per
#                         lesson at a time; each lesson has its own port.
#
# RUNENV, when set, is run silently before each command.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
MD_LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MD_COURSE=$(dirname "$MD_LAB")
LESSON=$(cd "$(dirname "$0")" && pwd)
LAB() { bash "$MD_COURSE/lab.sh" "$@"; }
PIDF=/tmp/md-serve-$(basename "$LESSON").pid
LOGF=/tmp/md-serve-$(basename "$LESSON").log

shown() { local d=$1; d=${d/#\/home\/ana/\~}; printf '%s' "$d"; }
run() {
  local dir=$1; shift
  printf 'ana@dev:%s$ %s\n' "$(shown "$dir")" "$*"
  local out
  out=$(LAB as "${RUNENV:+$RUNENV; }cd $dir && $*" 2>&1; printf x)
  out=${out%x}
  printf '%s' "$out"
  [ -z "$out" ] || [ "${out: -1}" = $'\n' ] || printf '\n'
  return 0
}
quiet() { local dir=$1; shift; LAB as "cd $dir && $*" >/dev/null 2>&1; return 0; }
block() { printf '##### %s\n' "$1"; }
put() {   # put MD FILE DEST
  local md=$1 file=$2 dest=$3
  mkdir -p "$(dirname "$dest")"
  python3 "$MD_LAB/extract.py" "$LESSON/$md" "$file" > "$dest" ||
    { echo "put: no listing of $file in $md" >&2; exit 1; }
  chown -R ana:ana /home/ana
}
SERVER=
serve() { # serve DIR PORT 'command'
  local dir=$1 port=$2; shift 2
  LAB as "cd $dir && { setsid bash -c 'echo \$\$ > $PIDF; exec $*' </dev/null >$LOGF 2>&1 & }"
  for _ in $(seq 100); do
    curl -s -o /dev/null "http://127.0.0.1:$port/" && { SERVER=1; return 0; }
    sleep 0.2
  done
  echo "serve: nothing answered on port $port" >&2; cat $LOGF >&2; exit 1
}
unserve() {
  [ -n "$SERVER" ] || return 0
  kill -- -"$(cat $PIDF)" 2>/dev/null; rm -f $PIDF
  SERVER=; sleep 0.5
}
trap unserve EXIT
