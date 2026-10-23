# lib.sh: what every captures.sh in this course types with. Sourced, not run.
#
# A capture prints blocks, each headed "##### NAME". lab/fill.py pastes each
# block into the fence of the lesson whose typed lines are the same, so a
# transcript in a lesson is always what the last run printed.

COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAB_SH=$COURSE/lab.sh
STATE=/tmp/anglab
SNAP=/var/tmp/anglab-snapshots
install -d -o ana -g ana -m 755 $STATE 2>/dev/null || true
install -d -m 755 $SNAP

block() { printf '##### %s\n' "$1"; }

# session DIR 'command' ...: one terminal, opened fresh in DIR, with each
# command typed into it. The prompt is printed as bash would draw it.
session() {
  local dir=$1 script c
  shift
  # $? is kept from one command to the next, so `echo $?` answers about the
  # command before it and not about the printf that drew the prompt.
  script="cd $dir; __rc=0"
  for c in "$@"; do
    script+=$'\n'"printf 'ana@dev:%s\$ %s\\n' \"\$(dirs +0)\" $(printf '%q' "$c")"$'\n'"(exit \$__rc); $c 2>&1; __rc=\$?"
  done
  bash "$LAB_SH" script "$script" 2>&1 || true
}

# quiet DIR 'command': run something as ana and show nothing, for the steps
# a lesson has already shown (or says it does not show).
quiet() { bash "$LAB_SH" script "cd $1; $2" >/dev/null 2>&1 || true; }

# shown MD NAME DEST [N]: take the file NAME out of the lesson MD and save it,
# as ana, at DEST. The lesson shows it whole; this is the same text.
shown() {
  local text
  text=$(python3 "$COURSE/lab/shown.py" "$1" "$2" ${4:-}) || { echo "shown: $2 is not in $1" >&2; exit 1; }
  bash "$LAB_SH" script "mkdir -p \"\$(dirname $3)\" && cat > $3" <<<"$text"
}
# save SECTION PATH [N]: the file PATH of the planner, as SECTION.md of the
# lesson being captured shows it, saved where the student saves it.
save() { shown "$PWD/$1.md" "$2" "~/planner/$2" "${3:-}"; }

# bg NAME DIR 'command': start a program in "a second terminal", as ana. What
# it prints goes to a log that bg_show prints with the prompt it was typed at.
bg() {
  local name=$1 dir=$2 cmd=$3
  printf '%s\n%s\n' "$dir" "$cmd" > $STATE/$name.cmd
  bash "$LAB_SH" script "cd $dir; setsid bash -c $(printf '%q' "$cmd") > $STATE/$name.log 2>&1 < /dev/null & echo \$! > $STATE/$name.pid"
}
# bg_show NAME: that terminal as it stands, prompt first.
bg_show() {
  local dir cmd
  { read -r dir; read -r cmd; } < $STATE/$1.cmd
  printf 'ana@dev:%s$ %s\n' "$dir" "$cmd"
  cat $STATE/$1.log
}
# bg_stop NAME [SIGNAL]: what Ctrl-C (INT) would do, and wait for it.
bg_stop() {
  local pid
  pid=$(cat $STATE/$1.pid 2>/dev/null) || return 0
  kill -"${2:-INT}" -- -"$pid" 2>/dev/null || true
  for _ in $(seq 50); do kill -0 -- -"$pid" 2>/dev/null || { rm -f $STATE/$1.pid; return 0; }; sleep 0.1; done
  kill -KILL -- -"$pid" 2>/dev/null || true
  rm -f $STATE/$1.pid
}

# wait_port PORT: until something answers on 127.0.0.1:PORT.
wait_port() {
  for _ in $(seq 600); do
    (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && return 0
    sleep 0.1
  done
  echo "wait_port: nothing answered on $1" >&2
}
# wait_log NAME TEXT: until the program in that terminal has printed TEXT.
wait_log() {
  for _ in $(seq 600); do
    grep -qF -- "$2" $STATE/$1.log 2>/dev/null && return 0
    sleep 0.1
  done
  echo "wait_log: $1 never printed $2" >&2
}

# serve: `ng serve` in a second terminal, until the first build is done.
serve() {
  bg serve '~/planner' 'npx ng serve'
  wait_log serve 'Local:'
  wait_port 4200
}

# THE PROJECT, from lesson to lesson. restore LESSON puts ~/planner back as
# the captures of LESSON left it; snapshot LESSON saves it. node_modules stays
# where it is and is reinstalled only when the lockfile says it has to be.
snapshot() {
  rm -rf "$SNAP/$1" && mkdir -p "$SNAP/$1"
  tar -C /home/ana -cf "$SNAP/$1/planner.tar" --exclude=planner/node_modules \
    --exclude=planner/dist --exclude=planner/.angular planner
}
restore() {
  [ -f "$SNAP/$1/planner.tar" ] || { echo "restore: no snapshot of $1; capture it first" >&2; exit 1; }
  local lock=""
  [ -f /home/ana/planner/package-lock.json ] && lock=$(sha1sum < /home/ana/planner/package-lock.json)
  find /home/ana/planner -mindepth 1 -maxdepth 1 ! -name node_modules -exec rm -rf {} + 2>/dev/null || true
  tar -C /home/ana -xf "$SNAP/$1/planner.tar"
  chown -R ana: /home/ana/planner
  if [ "$lock" != "$(sha1sum < /home/ana/planner/package-lock.json)" ] || [ ! -d /home/ana/planner/node_modules ]; then
    quiet '~/planner' 'npm ci'
  fi
}

# look ARGS: the line a student types, typed into ~/planner.
look() { session '~/planner' "look $*"; }

# cap DIR 'command' ...: one fence's transcript, in a block of its own. The
# block is named by a counter: fill.py finds a fence by what was typed, never
# by the name.
CAPN=0
cap() { CAPN=$((CAPN + 1)); block "t$CAPN"; session "$@"; }
# cap_look ARGS: the same for one look.
cap_look() { CAPN=$((CAPN + 1)); block "t$CAPN"; look "$@"; }
# cap_bg NAME: the same for a second terminal, as it stands.
cap_bg() { CAPN=$((CAPN + 1)); block "t$CAPN"; bg_show "$1"; }
