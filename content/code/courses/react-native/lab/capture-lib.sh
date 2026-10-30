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
#   start_from LESSON     copy ~/planner as lesson LESSON's captures left it
#                         into this lesson's home (node_modules as hard links)
#
# Every lesson is recorded in a home of its own (lab.sh says why). Its captures
# start from an EMPTY home, or from what an earlier lesson left, with
# start_from; the script's header says which.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
RN_LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RN_COURSE=$(dirname "$RN_LAB")
LESSON=$(cd "$(dirname "$0")" && pwd)
LID=$(basename "$LESSON")
LAB() { bash "$RN_COURSE/lab.sh" "$@"; }
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
put() {   # put MD FILE DEST [N]: the Nth listing of FILE in MD, the first by default
  local md=$1 file=$2 dest=$3 n=${4:-1}
  local real=$H${dest#/home/ana}
  mkdir -p "$(dirname "$real")"
  python3 "$RN_LAB/extract.py" "$LESSON/$md" "$file" "$n" > "$real" ||
    { echo "put: no listing of $file in $md" >&2; exit 1; }
  chown -R ana:ana "$H"
}
SERVERS=
serve() { # serve DIR PORT 'command'
  # Each server runs under its own `lab.sh as`, in the background, in a session
  # of its own: a server started inside a `run` dies with that run's PID
  # namespace the moment the command returns. unserve kills every session.
  # What the server prints goes to ~/.serve-PORT.log; `served PORT` shows it.
  local dir=$1 port=$2; shift 2
  setsid bash "$RN_COURSE/lab.sh" as "$LID" "cd $dir && exec $*" </dev/null >"$H/.serve-$port.log" 2>&1 &
  SERVERS="$SERVERS $!"
  for _ in $(seq 100); do
    curl -s --noproxy '*' -o /dev/null "http://127.0.0.1:$port/" && return 0
    sleep 0.2
  done
  echo "serve: nothing answered on port $port" >&2; cat "$H/.serve-$port.log" >&2; exit 1
}
served() { cat "$H/.serve-$1.log"; }
unserve() {
  [ -n "$SERVERS" ] || return 0
  for s in $SERVERS; do kill -- -"$s" 2>/dev/null; wait "$s" 2>/dev/null; done
  rm -f "$H"/.serve-*.log
  SERVERS=; sleep 0.5
}
trap unserve EXIT
start_from() {
  local from; from=$(LAB path "$1")
  [ -d "$from/planner" ] || { echo "start_from: lesson $1 left no ~/planner; record it first" >&2; exit 1; }
  rm -rf "$H/planner"
  tar -C "$from" --exclude=planner/node_modules --exclude=planner/android --exclude=planner/ios --exclude=planner/dist -cf - planner | tar -C "$H" -xf -
  [ -d "$from/planner/node_modules" ] && cp -al "$from/planner/node_modules" "$H/planner/node_modules"
  chown -R ana:ana "$H/planner"
}
# commit DIR 'YYYY-MM-DD HH:MM' 'message': a commit with a fixed date, so the
# hashes repeat
commit() {
  LAB as "$LID" "cd $1 && git add -A && GIT_AUTHOR_DATE='$2:00 -0300' GIT_COMMITTER_DATE='$2:00 -0300' git commit -q -m '$3'" >/dev/null
}
# jsonedit DIR FILE 'js': change a JSON file the way the lesson asks the student
# to in an editor; `c` is the parsed file, and it is written back with two
# spaces, as the templates write it.
jsonedit() {
  LAB as "$LID" "cd $1 && node -e 'const fs=require(\"fs\");const c=JSON.parse(fs.readFileSync(\"$2\"));$3;fs.writeFileSync(\"$2\",JSON.stringify(c,null,2)+\"\\n\")'"
}
