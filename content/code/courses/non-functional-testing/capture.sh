# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes. Every command runs inside a fresh copy
# of the lab's machine, `nft`, as ana, through lab.sh.
#
#   machine NAME [net]    a fresh copy of the machine for this lesson (lab.sh up)
#   shown FILE.md…        copy every whole file those lessons show into ~ana
#   run 'command'         print ana's prompt and the command, then run it and
#                         print everything it wrote, stdout and stderr together
#   quiet 'command'       run as ana without showing: the lab's housekeeping
#   asroot 'command'      run as root without showing
#   serve 'command' [LOG] start a server in the background, as ana, in the
#                         current directory, its output to /tmp/LOG.log
#                         (default server), and wait until 127.0.0.1:${PORT:-8000}
#                         answers. The lesson tells the student to run it in a
#                         second terminal; `log` prints what that terminal shows
#   log [LOG]             what a server started by `serve` has printed so far
#   stop [LOG]            stop it
#   at DIR                the directory the next commands run in, ~ by default
#   block NAME            a marker between transcripts, never quoted
#
# A command runs with no terminal attached, which is why nothing here is in
# colour and no program pages its output. The machine is torn down on exit.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE='~'
MACHINE=''

lab() { bash "$COURSE/lab.sh" "$@"; }
machine() { MACHINE=$1; lab up "$@"; trap 'lab down "$MACHINE"' EXIT; }
shown() { lab shown "$MACHINE" "$@"; }
at() { HERE=$1; }
dir() { [ "$HERE" = '~' ] && echo '$HOME' || echo "${HERE/#\~/\$HOME}"; }
run() {
  printf 'ana@nft:%s$ %s\n' "$HERE" "$1"
  lab as "$MACHINE" "cd $(dir) && export PAGER=cat COLUMNS=100 && { $1 ; }" 2>&1 || true
}
quiet() { lab as "$MACHINE" "cd $(dir) && { $1 ; }" >/dev/null 2>&1 || true; }
asroot() { lab root "$MACHINE" "$1" >/dev/null 2>&1 || true; }
serve() {
  local name=${2:-server} port=${PORT:-8000}
  lab as "$MACHINE" "cd $(dir) && { setsid bash -c 'exec $1' </dev/null >/tmp/$name.log 2>&1 & echo \$! > /tmp/$name.pid; }" \
    >/dev/null 2>&1
  lab as "$MACHINE" "for i in \$(seq 100); do (exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null && exit 0; sleep 0.1; done; exit 1" \
    || { echo "serve: nothing answered on $port" >&2; lab as "$MACHINE" "cat /tmp/$name.log" >&2; }
}
log() { lab as "$MACHINE" "cat /tmp/${1:-server}.log"; }
stop() { lab as "$MACHINE" "kill \$(cat /tmp/${1:-server}.pid) 2>/dev/null; sleep 0.3" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
