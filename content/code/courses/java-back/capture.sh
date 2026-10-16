# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes. Every command runs as ana, through
# lab.sh, and the whole run holds the lab's lock, so two capture scripts never
# share the machine.
#
#   run 'command'        print ana's prompt and the command, then run it and
#                        print what it wrote, stdout and stderr together
#   quiet 'command'      run as ana without showing: housekeeping
#   asroot 'command'     run as root without showing
#   at DIR               the directory the next commands run in (~ by default),
#                        written as the prompt writes it: ~/bookshop
#   put PATH <<'EOF'     a file ana wrote, PATH relative to ~
#   take MD PREFIX PATH  the fence of MD whose first line starts with PREFIX,
#                        written to PATH as ana: what the lesson shows is what
#                        runs
#   shown MD FILE...     every FILE of ~/bookshop (paths relative to it) is
#                        printed in MD byte for byte; a mismatch stops the run
#   stage LESSON-ID      ~/bookshop as it is at the end of that lesson
#   db | start ARGS | stop    as lab.sh
#   block NAME           a marker between transcripts, never quoted
#
# A command runs with no terminal attached, which is why nothing here pages
# and Maven, run with -B where a lesson types it or not, prints no colour; any
# colour code left is stripped, and the text is what the program printed.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE='~'
exec 9>/var/tmp/java-back.lock
flock 9
export JB_LOCKED=1

lab() { bash "$COURSE/lab.sh" "$@" 9>&-; }
at() { HERE=$1; }
dir() { [ "$HERE" = '~' ] && echo '$HOME' || echo "${HERE/#\~/\$HOME}"; }
run() {
  printf 'ana@vm:%s$ %s\n' "$HERE" "$1"
  lab exec "cd $(dir) && export PAGER=cat COLUMNS=100 && { $1 ; }" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true
}
quiet() { lab exec "cd $(dir) && { $1 ; }" >/dev/null 2>&1 || true; }
asroot() { bash -c "$1" >/dev/null 2>&1 9>&- || true; }
put() { lab exec "mkdir -p \"\$(dirname ~/$1)\" && cat > ~/$1"; }
take() { python3 "$COURSE/lab/fence.py" extract "$1" "$2" | put "$3"; }
shown() {
  local md; md=$(realpath "$1"); shift
  ( cd /home/ana/bookshop && python3 "$COURSE/lab/fence.py" check "$md" "$@" ) \
    || { echo '!!! a file the lesson shows is not the file the lab built' >&2; exit 1; }
}
stage() { lab stage "$1"; }
db() { lab db; }
start() { lab start "$@"; }
stop() { lab stop; }
block() { printf '##### %s\n' "$1"; }
