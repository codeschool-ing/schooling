# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes. Every command runs inside the lab's
# server, `vm`, as ana, through lab.sh.
#
#   run 'command'        print ana's prompt and the command, then run it and
#                        print everything it wrote, stdout and stderr together
#   shown 'cmd' 'actual' print cmd, run actual: for a failure the lesson stages
#   quiet 'command'      run as ana without showing: the lab's housekeeping
#   asroot 'command'     run as root without showing
#   put FILE <<'EOF'     a file ana wrote (sudo tee, so it may be anywhere);
#                        the lesson shows its content as a fence of its own
#   from MD PATH [DEST]  the file PATH exactly as the lesson's MD shows it (a
#                        fence whose first line names it, or an example whose
#                        `file` is it), written to DEST, which defaults to
#                        PATH under the current directory
#   serve NAME 'command' start a server as ana in the background, its output
#                        in /tmp/NAME.log; `stop NAME` ends it
#   at DIR               the directory the next commands run in, ~ by default
#   block NAME           a marker between transcripts, never quoted
#
# A command runs with no terminal attached, which is why nothing here is in
# colour and no program pages its output.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE='~'

lab() { bash "$COURSE/lab.sh" "$@"; }
at() { HERE=$1; }
dir() { [ "$HERE" = '~' ] && echo '$HOME' || echo "${HERE/#\~/\$HOME}"; }
ENVS='export PAGER=cat SYSTEMD_PAGER=cat SYSTEMD_COLORS=0 COLUMNS=100 NO_COLOR=1 UV_NO_PROGRESS=1 PYTHONUNBUFFERED=1'
run() {
  printf 'ana@vm:%s$ %s\n' "$HERE" "$1"
  lab as "cd $(dir) && $ENVS && { $1 ; }" 2>&1 || true
}
shown() { # shown COMMAND ACTUAL: print COMMAND, run ACTUAL (the script header says why)
  printf 'ana@vm:%s$ %s\n' "$HERE" "$1"
  lab as "cd $(dir) && $ENVS && { $2 ; }" 2>&1 || true
}
quiet() { lab as "cd $(dir) && $ENVS && { $1 ; }" >/dev/null 2>&1 || true; }
asroot() { lab root "$1" >/dev/null 2>&1 || true; }
put() { lab as "sudo tee '$1' >/dev/null"; }
from() {
  local md=$1 path=$2 dest=${3:-}
  [ -n "$dest" ] || dest="$(dir)/$path"
  python3 "$COURSE/lab/mdfile.py" "$LESSON/$md" "$path" \
    | lab as "mkdir -p \"\$(dirname \"$dest\")\" && cat > \"$dest\"" \
    || { echo "from: $path is not in $md" >&2; exit 1; }
}
serve() {
  lab as "cd $(dir) && $ENVS && setsid bash -c '$2' </dev/null >/tmp/$1.log 2>&1 & echo \$! > /tmp/$1.pid"
  sleep "${WAIT:-3}"
}
stop() { lab as "kill -- -\$(cat /tmp/$1.pid) 2>/dev/null; sleep 1; rm -f /tmp/$1.pid" || true; }
block() { printf '##### %s\n' "$1"; }
