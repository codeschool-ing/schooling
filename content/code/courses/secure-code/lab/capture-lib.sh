# Sourced by every lesson's captures.sh. It is the author's, like lab.sh.
#
#   run DIR 'command'       print the prompt in DIR, then run the command there
#                           and print what it printed (stdout and stderr)
#   block NAME              start a named block: lab/fill.py pastes each block
#                           into the fence of the lesson that holds it
#   put MD FILE [N] DEST    write the Nth listing of FILE in the lesson's MD
#                           (see lab/extract.py) to DEST: the file the lesson
#                           shows is the file the capture runs
#   serve DIR 'command'     start a server in the background in DIR, wait for
#                           port 5000, and remember its pid; `unserve` stops it
#
# The whole script re-executes itself inside a private mount namespace where
# LAB_HOME is bound over /home (lab.sh says why).

if [ -z "${IN_SC_LAB:-}" ]; then
  export LAB_HOME=${LAB_HOME:-/var/tmp/secure-code-home}
  mkdir -p "$LAB_HOME/ana"
  exec unshare --mount env IN_SC_LAB=1 LAB_HOME="$LAB_HOME" bash "$0" "$@"
fi
# /home also holds the checkout this script runs from, so it is put back
# beside ana's: a tmpfs over /home, then the two bound into it.
mkdir -p /var/tmp/secure-code-real-home
mount --bind /home /var/tmp/secure-code-real-home
mount -t tmpfs tmpfs /home
for d in /var/tmp/secure-code-real-home/*; do
  [ -d "$d" ] || continue
  mkdir -p "/home/$(basename "$d")"; mount --bind "$d" "/home/$(basename "$d")"
done
mkdir -p /home/ana; mount --bind "$LAB_HOME/ana" /home/ana

set -uo pipefail
# bash reports the stopped server as "Terminated" on its own stderr; that line
# is the shell's, not any program's, and is kept out of the transcripts.
exec 2> >(grep --line-buffered -v '^Terminated$' >&2)
export HOME=/home/ana TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat GIT_PAGER=cat
export PIP_DISABLE_PIP_VERSION_CHECK=1
SC_LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON=$(cd "$(dirname "$0")" && pwd)
VENV=${VENV:-1}
SERVER_PID=

run() {
  local dir=$1; shift
  local shown=${dir/#\/home\/ana/\~}
  local pre=''; [ "$VENV" = 1 ] && pre='(.venv) '
  printf '%sana@vm:%s$ %s\n' "$pre" "$shown" "$*"
  local act=''; [ "$VENV" = 1 ] && act='. /home/ana/sc/.venv/bin/activate && '
  if [[ "$*" == *"pip "* ]]; then   # one pip at a time in the shared environment
    ( flock 8; cd "$dir" && bash -c "$act$*" ) 8>/var/tmp/secure-code-pip.lock 2>&1
  else
    ( cd "$dir" && bash -c "$act$*" ) 2>&1
  fi
  return 0
}
block() { printf '##### %s\n' "$1"; }
put() {   # put MD FILE [N] DEST
  local md=$1 file=$2 n=1 dest
  if [ $# -eq 4 ]; then n=$3; dest=$4; else dest=$3; fi
  mkdir -p "$(dirname "$dest")"
  python3 "$SC_LAB/extract.py" "$LESSON/$md" "$file" "$n" > "$dest" || { echo "put: no listing $file #$n in $md" >&2; exit 1; }
}
serve() {
  exec 9>/var/tmp/secure-code-port.lock
  flock 9
  local dir=$1; shift
  local act=''; [ "$VENV" = 1 ] && act='. /home/ana/sc/.venv/bin/activate && '
  rm -f /var/tmp/secure-code-server.pid
  ( cd "$dir" && setsid bash -c "echo \$\$ > /var/tmp/secure-code-server.pid; $act exec $*" </dev/null >/var/tmp/secure-code-server.log 2>&1 & )
  for _ in $(seq 50); do [ -s /var/tmp/secure-code-server.pid ] && break; sleep 0.1; done
  SERVER_PID=$(cat /var/tmp/secure-code-server.pid)
  for _ in $(seq 50); do
    if curl -s -o /dev/null http://127.0.0.1:5000/ 2>/dev/null; then return 0; fi
    sleep 0.2
  done
  echo "serve: nothing answered on port 5000" >&2; cat /var/tmp/secure-code-server.log >&2; exit 1
}
unserve() {
  { [ -n "$SERVER_PID" ] && kill -- -"$SERVER_PID"; kill "$SERVER_PID"; sleep 0.3; } 2>/dev/null
  SERVER_PID=
  flock -u 9 2>/dev/null || true
}
trap 'unserve' EXIT
fresh_repo() {   # fresh_repo DIR: an empty folder that is a git repository, as a lesson starts one
  rm -rf "$1"; mkdir -p "$1"; git -C "$1" init -q -b main
  git -C "$1" config user.name ana; git -C "$1" config user.email ana@vereda.example
}
commit() {       # commit DIR 'YYYY-MM-DD HH:MM' 'message': a commit with a fixed date
  ( cd "$1" && git add -A && GIT_AUTHOR_DATE="$2:00 -0300" GIT_COMMITTER_DATE="$2:00 -0300" git commit -q -m "$3" )
}
