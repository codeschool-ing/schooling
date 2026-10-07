# What every lesson's captures.sh sources: the few verbs a capture is made of.
#
#   block NAME          the section the transcripts below belong to
#   on 'command'        ana types it in ~/desk; the prompt and what it printed
#   home 'command'      the same, in her home directory, before ~/desk exists
#   tty 'command'       as `on`, through a terminal of 100 columns, and what the
#                       screen showed at the end (lab/screen.py): for ollama's
#                       progress bars and its word-at-a-time answers
#   quote ARGS          a quotation from lab/sources.py: the repository, commit
#                       and path, then the numbered lines. No prompt, because
#                       the student is never asked to run it
#   give FILE MD LANG N   write ~/desk/FILE from the Nth LANG fence of the lesson's
#                       MD (or `example NAME`), so the capture runs exactly what
#                       the lesson shows
#
# Sourced with the lesson's directory as the working directory.

LAB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB_SH=${LAB_SH:-$LAB_DIR/../lab.sh}
AUTHOR=/opt/aimodels-author

lab() { bash "$LAB_SH" "$@"; }
block() { printf '##### %s\n' "$1"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 < /dev/null || true; }
# ana's environment outside ~/desk: nothing of root's, except the way out.
ana() {
  runuser -u ana -- env -i HOME=/home/ana USER=ana TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PATH=/usr/local/bin:/usr/bin:/bin \
    ${HTTPS_PROXY:+HTTPS_PROXY=$HTTPS_PROXY https_proxy=$HTTPS_PROXY NO_PROXY=${NO_PROXY:-} no_proxy=${NO_PROXY:-}} \
    bash -c "cd ~; $*"
}
home() { printf 'ana@desk:~$ %s\n' "$*"; ana "$*" 2>&1 < /dev/null || true; }
hometty() {  # as `tty`, in the home directory
  printf 'ana@desk:~$ %s\n' "$*"
  ana "script -qfec \"stty cols 100 rows 400; $*\" /dev/null" 2>&1 | $AUTHOR/bin/python "$LAB_DIR/screen.py" 100
}
tty() {
  printf 'ana@desk:~/desk$ %s\n' "$*"
  lab exec ana "script -qfec \"stty cols 100 rows 400; $*\" /dev/null" 2>&1 | $AUTHOR/bin/python "$LAB_DIR/screen.py" 100
}
quote() { SOURCES_CACHE=$AUTHOR/share/sources $AUTHOR/bin/python "$LAB_DIR/sources.py" "$@"; }
give() {
  local file=$1; shift
  $AUTHOR/bin/python "$LAB_DIR/extract.py" "$@" > /tmp/give.$$ || exit 1
  lab exec ana "mkdir -p \"\$(dirname '$file')\" && cat > '$file'" < /tmp/give.$$
  rm -f /tmp/give.$$
}

# The relay lesson 9 shows (relay.py), started in ~/desk the way the student
# starts it in a second terminal, with a fresh wire.jsonl, and stopped after.
relay_up() {
  lab exec ana "rm -f wire.jsonl; setsid python relay.py $* > relay.out 2>&1 < /dev/null & echo \$! > relay.pid" < /dev/null
  # a bare TCP connect, so the readiness check is not a request the relay logs or answers with a --fail
  for _ in $(seq 25); do (exec 3<>/dev/tcp/127.0.0.1/8500) 2>/dev/null && return 0; sleep 0.2; done
}
relay_down() { lab exec ana 'kill $(cat relay.pid) 2>/dev/null; rm -f relay.pid' < /dev/null; sleep 0.3; }

# session: several commands typed in ONE terminal, so that what the first sets
# (an export, a cd) holds for the rest; each is printed with its prompt, then
# run. The commands come one per line on stdin.
session() {
  local script
  script=$($AUTHOR/bin/python -c '
import shlex, sys
for line in sys.stdin.read().splitlines():
    if line.strip():
        print("printf \"%s\\n\" " + shlex.quote("ana@desk:~/desk$ " + line))
        print(line + " 2>&1")')
  lab exec ana "$script" < /dev/null
}

# via: as `on`, in a terminal where the student has sent both libraries to the
# relay with the export line lessons 16 to 21 show once, at their start.
RELAY_EXPORT='export OPENAI_BASE_URL=http://127.0.0.1:8500/v1 ANTHROPIC_BASE_URL=http://127.0.0.1:8500'
via() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$RELAY_EXPORT; $*" 2>&1 < /dev/null || true; }
