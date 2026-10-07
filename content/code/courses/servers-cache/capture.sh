# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes. Every command runs inside the lab's
# server, `web`, as ana, through lab.sh.
#
#   run 'command'        print ana's prompt and the command, then run it and
#                        print everything it wrote, stdout and stderr together
#   quiet 'command'      run as ana without showing: the lab's housekeeping
#   asroot 'command'     run as root without showing
#   put FILE <<'EOF'     a file ana wrote (sudo tee, so it may be anywhere);
#                        the lesson shows its content as a fence of its own
#   at DIR               the directory the next commands run in, ~ by default
#   block NAME           a marker between transcripts, never quoted
#
# A command runs with no terminal attached, which is why nothing here is in
# colour and no program pages its output.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE='~'

lab() { bash "$COURSE/lab.sh" "$@"; }
at() { HERE=$1; }
dir() { [ "$HERE" = '~' ] && echo '$HOME' || echo "${HERE/#\~/\$HOME}"; }
run() {
  printf 'ana@web:%s$ %s\n' "$HERE" "$1"
  lab as "cd $(dir) && export PAGER=cat SYSTEMD_PAGER=cat SYSTEMD_COLORS=0 COLUMNS=100 && { $1 ; }" 2>&1 || true
}
quiet() { lab as "cd $(dir) && { $1 ; }" >/dev/null 2>&1 || true; }
asroot() { lab root "$1" >/dev/null 2>&1 || true; }
put() { lab as "sudo tee '$1' >/dev/null"; }
block() { printf '##### %s\n' "$1"; }
