# lib.sh: what every captures.sh in this course types with. Sourced, not run.
#
# A capture prints blocks, each headed "##### NAME". lab/fill.py pastes each
# block into the fence of the lesson whose typed lines are the same, so a
# transcript in a lesson is always what the last run printed.

COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAB_SH=$COURSE/lab.sh
STATE=/tmp/vuelab
install -d -o ana -g ana -m 755 $STATE 2>/dev/null || true

block() { printf '##### %s\n' "$1"; }

# session DIR 'command' ...: one terminal, opened fresh in DIR, with each
# command typed into it. The prompt is printed as bash would draw it.
session() {
  local dir=$1 script c
  shift
  script="cd $dir"
  for c in "$@"; do
    script+=$'\n'"printf 'ana@dev:%s\$ %s\\n' \"\$(dirs +0)\" $(printf '%q' "$c")"$'\n'
    # With CLOCK set (see bg), the command runs on the staged clock, browser and all.
    if [ -n "${CLOCK:-}" ]; then
      script+="faketime -f $(printf '%q' "@$CLOCK") bash -c $(printf '%q' "$c") 2>&1"
    else
      script+="$c 2>&1"
    fi
  done
  bash "$LAB_SH" script "$script" 2>&1 || true
}

# quiet DIR 'command': run something as ana and show nothing, for the steps
# a lesson has already shown (or says it does not show).
quiet() { bash "$LAB_SH" script "cd $1; $2" >/dev/null 2>&1 || true; }

# shown MD NAME DEST: take the file NAME out of the lesson MD and save it, as
# ana, at DEST. The lesson shows it whole; this is the same text.
shown() {
  local text
  text=$(python3 "$COURSE/lab/shown.py" "$1" "$2") || { echo "shown: $2 is not in $1" >&2; exit 1; }
  bash "$LAB_SH" script "mkdir -p \"\$(dirname $3)\" && cat > $3" <<<"$text"
}

# bg NAME DIR 'command': start a program in "a second terminal", as ana. What
# it prints goes to a log that bg_show prints with the prompt it was typed at.
bg() {
  local name=$1 dir=$2 cmd=$3 run=$3
  printf '%s\n%s\n' "$dir" "$cmd" > $STATE/$name.cmd
  # A server whose clock is staged: CLOCK='2026-10-21 10:00:00' starts its
  # clock there (it then runs on), and SERVER_TZ gives it another zone, at the
  # same instant. Both
  # are libfaketime and the environment, and neither is in what the
  # transcript shows typed.
  if [ -n "${CLOCK:-}" ]; then
    local at=$CLOCK
    # CLOCK is a time in ana's zone; the same instant in the server's own.
    [ -n "${SERVER_TZ:-}" ] && at=$(TZ=$SERVER_TZ date -d "TZ=\"America/Sao_Paulo\" $CLOCK" '+%F %T')
    run="${SERVER_TZ:+TZ=$SERVER_TZ }faketime -f $(printf '%q' "@$at") bash -c $(printf '%q' "$cmd")"
  fi
  bash "$LAB_SH" script "cd $dir; setsid bash -c $(printf '%q' "$run") > $STATE/$name.log 2>&1 < /dev/null & echo \$! > $STATE/$name.pid"
}
# bg_show NAME: that terminal as it stands, prompt first.
bg_show() {
  local dir cmd
  { read -r dir; read -r cmd; } < $STATE/$1.cmd
  dir=${dir/#\~/\~}
  printf 'ana@dev:%s$ %s\n' "$dir" "$cmd"
  cat $STATE/$1.log
}
# bg_stop NAME [SIGNAL]: what Ctrl-C (INT) or a kill would do, and wait for it.
bg_stop() {
  local pid
  pid=$(cat $STATE/$1.pid 2>/dev/null) || return 0
  # The program runs in a session of its own, so the signal goes to its whole
  # process group, as a terminal's Ctrl-C does.
  kill -"${2:-INT}" -- -"$pid" 2>/dev/null || true
  for _ in $(seq 50); do kill -0 -- -"$pid" 2>/dev/null || return 0; sleep 0.1; done
  kill -KILL -- -"$pid" 2>/dev/null || true
}
bg_pid() { cat $STATE/$1.pid; }

# wait_port PORT: until something answers on 127.0.0.1:PORT.
wait_port() {
  for _ in $(seq 100); do
    (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && return 0
    sleep 0.1
  done
  echo "wait_port: nothing answered on $1" >&2
}

# repl DIR 'line' ...: Node's interactive prompt, typed at line by line. It
# runs on a pseudo-terminal, as it would in a terminal, so what was typed is
# echoed after each "> " the way a person sees it.
repl() {
  local dir=$1 feed="sleep 0.8" l
  shift
  for l in "$@"; do feed+="; printf '%s\\r' $(printf '%q' "$l"); sleep 0.4"; done
  printf 'ana@dev:%s$ node\n' "$dir"
  bash "$LAB_SH" script "cd $dir; ($feed; sleep 0.5) | script -qec node /dev/null" 2>&1 | tr -d '\r'
}

# bg_logpid NAME: the pid a program in "a second terminal" printed as "pid N",
# which is the number a person would read off the screen and type into kill.
bg_logpid() {
  local p
  for _ in $(seq 50); do
    p=$(grep -oE 'pid [0-9]+' $STATE/$1.log 2>/dev/null | head -1 | cut -d' ' -f2)
    [ -n "$p" ] && { echo "$p"; return 0; }
    sleep 0.1
  done
  echo "bg_logpid: $1 printed no pid" >&2
}

# THE PLANNER BETWEEN LESSONS. Each lesson's captures.sh defines files(), which
# puts the files that lesson leaves behind (every one of them shown whole in
# its .md) and runs `npm install` when package.json changed. A lesson starts
# from the state the one before it left:
#
#   start_from LESSON_ID     ~/vue as LESSON_ID left it
#
# It restores a snapshot that lesson's own capture saved, and when there is
# none it rebuilds ~/vue from nothing by replaying files() of every lesson up
# to it, in the course's order. `snapshot` saves the state at the end of a
# capture.
SNAP=$STATE/snap
LESSONS=$(python3 -c "import json;print(' '.join(json.load(open('$COURSE/course.json'))['lessons']))")
snapshot() {
  local id
  id=$(basename "$(pwd)")
  mkdir -p $SNAP
  tar -C /home/ana -cf $SNAP/$id.tar vue
}
start_from() {
  pkill -u ana -f 'vite|nuxt|node .output' 2>/dev/null || true
  if [ -f $SNAP/$1.tar ]; then
    rm -rf /home/ana/vue && tar -C /home/ana -xf $SNAP/$1.tar
    return
  fi
  bash "$LAB_SH" reset
  local l
  for l in $LESSONS; do
    ( cd "$COURSE/lessons/$l" && FILES_ONLY=1 . ./captures.sh ) || { echo "start_from: $l failed" >&2; exit 1; }
    [ "$l" = "$1" ] && break
  done
  ( cd "$COURSE/lessons/$1" && snapshot )
}

# dev NAME DIR 'command' PORT: a dev server "in a second terminal", and wait for it.
dev() { bg "$1" "$2" "$3"; wait_port "$4"; sleep 0.5; }

# look_at DIR URL [options]: the look command typed at ana's shell, as a session.
P='~/vue/planner'
