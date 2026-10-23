# Sourced by every lesson's captures.sh. It is the author's, like lab.sh.
#
#   run DIR 'command'       print the prompt in DIR, then run the command there
#                           and print what it printed (stdout and stderr)
#   block NAME              start a named block: lab/fill.py pastes each block
#                           into the fence of the lesson that holds it
#   put MD FILE [N] DEST    write the Nth listing of FILE in the lesson's MD
#                           (see lab/extract.py) to DEST: the file the lesson
#                           shows is the file the capture runs
#   serve PORT DIR 'cmd'    start a server in the background in DIR, wait until
#                           PORT answers, and remember it; `unserve PORT` stops
#                           it, and every server still running stops at exit
#   commit 'YYYY-MM-DD HH:MM' 'message'
#                           commit everything in ~/planner with a fixed date,
#                           so the hashes repeat
#   resume N                check out the tag lesson N's capture left, so a
#                           lesson starts where the previous one ended
#
# The whole script re-executes itself inside a private mount namespace where
# LAB_HOME is bound over /home/ana (lab.sh says why).

if [ -z "${IN_FQ_LAB:-}" ]; then
  export LAB_HOME=${LAB_HOME:-/var/tmp/front-quality-home}
  mkdir -p "$LAB_HOME/ana"
  exec unshare --mount env IN_FQ_LAB=1 LAB_HOME="$LAB_HOME" bash "$0" "$@"
fi
# /home also holds the checkout this script runs from, so it is put back
# beside ana's: a tmpfs over /home, then the two bound into it.
mkdir -p /var/tmp/front-quality-real-home
mount --bind /home /var/tmp/front-quality-real-home
mount -t tmpfs tmpfs /home
for d in /var/tmp/front-quality-real-home/*; do
  [ -d "$d" ] || continue
  mkdir -p "/home/$(basename "$d")"; mount --bind "$d" "/home/$(basename "$d")"
done
mkdir -p /home/ana; mount --bind "$LAB_HOME/ana" /home/ana

set -uo pipefail
# bash reports a stopped server as "Terminated" on its own stderr; that line
# is the shell's, not any program's, and is kept out of the transcripts.
exec 2> >(grep --line-buffered -v '^Terminated$' >&2)
# The student's Node is the one javascript lesson 1 installs in ~/.local/node;
# the recording machine's is the same release, 22.22.0, in /opt/node22.
export HOME=/home/ana USER=ana LOGNAME=ana TZ=America/Sao_Paulo LC_ALL=C.UTF-8 LANG=C.UTF-8
export PATH=/home/ana/.local/bin:/opt/node22/bin:/usr/local/bin:/usr/bin:/bin
export PAGER=cat GIT_PAGER=cat TERM=dumb NO_COLOR=1 FORCE_COLOR=0 CI=
export npm_config_update_notifier=false npm_config_fund=false npm_config_progress=false
export PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
unset NODE_PATH NPM_CONFIG_USERCONFIG
FQ_LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON=$(cd "$(dirname "$0")" && pwd)
P=/home/ana/planner
declare -A SERVERS=()

run() {
  local dir=$1; shift
  local shown=${dir/#\/home\/ana/\~}
  printf 'ana@dev:%s$ %s\n' "$shown" "$*"
  ( cd "$dir" && bash -c "$*" ) 2>&1
  return 0
}
block() { printf '##### %s\n' "$1"; }
put() {   # put MD FILE [N] DEST
  local md=$1 file=$2 n=1 dest
  if [ $# -eq 4 ]; then n=$3; dest=$4; else dest=$3; fi
  mkdir -p "$(dirname "$dest")"
  python3 "$FQ_LAB/extract.py" "$LESSON/$md" "$file" "$n" > "$dest" || { echo "put: no listing $file #$n in $md" >&2; exit 1; }
}
serve() {   # serve PORT DIR 'command'
  local port=$1 dir=$2; shift 2
  local pidf=/var/tmp/front-quality-server-$port.pid
  rm -f "$pidf"
  ( cd "$dir" && setsid bash -c "echo \$\$ > $pidf; exec $*" </dev/null >/var/tmp/front-quality-server-$port.log 2>&1 & )
  for _ in $(seq 50); do [ -s "$pidf" ] && break; sleep 0.1; done
  SERVERS[$port]=$(cat "$pidf")
  for _ in $(seq 100); do
    if curl -s -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null || curl -s -o /dev/null "http://localhost:$port/" 2>/dev/null; then return 0; fi
    sleep 0.2
  done
  echo "serve: nothing answered on port $port" >&2; cat /var/tmp/front-quality-server-$port.log >&2; exit 1
}
unserve() {
  local port=$1 pid=${SERVERS[$1]:-}
  { [ -n "$pid" ] && kill -- -"$pid"; kill "$pid"; sleep 0.3; } 2>/dev/null
  unset "SERVERS[$port]"
}
unserve_all() { local p; for p in "${!SERVERS[@]}"; do unserve "$p"; done; }
trap 'unserve_all' EXIT
commit() {   # commit 'YYYY-MM-DD HH:MM' 'message'
  ( cd "$P" && git add -A && GIT_AUTHOR_DATE="$1:00 -0300" GIT_COMMITTER_DATE="$1:00 -0300" git commit -q -m "$2" )
}
resume() {   # resume N: start from where lesson N's capture left the project
  git -C "$P" rev-parse -q --verify "refs/tags/lesson-$1" >/dev/null || { echo "resume: lesson $1 has not been captured" >&2; exit 1; }
  git -C "$P" checkout -q -f "lesson-$1" && git -C "$P" clean -qfdx -e node_modules
  git -C "$P" checkout -q -B main
  ( cd "$P" && npm ci --silent >/dev/null 2>&1 )
}
leave() {    # leave N: tag where this lesson ended, for the next one
  git -C "$P" tag -f "lesson-$1" >/dev/null
}
fix() {   # fix FILE 'old' 'new': one exact replacement, which must match once
  python3 - "$P/$1" "$2" "$3" <<'PY'
import sys
p, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p).read()
assert s.count(old) == 1, (p, old)
open(p, 'w').write(s.replace(old, new))
PY
}
