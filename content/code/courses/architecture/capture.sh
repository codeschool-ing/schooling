# Sourced by every lesson's captures.sh: the functions that turn a script into
# the transcripts the lesson quotes. Every command runs as ana, through lab.sh.
#
#   at DIR                 the directory the next commands run in (~ by default)
#   save LESSON FILE DEST  extract the lesson's schooling-example FILE into DEST,
#                          as the student saves it with the copy button
#   run 'command'          print ana's prompt and the command, then run it and
#                          print everything it wrote, stdout and stderr together
#   quiet 'command'        run as ana without showing: the lab's housekeeping
#   prebuild               build the images of the project in the current DIR
#                          (lab.sh says why), not shown
#   block NAME             a marker between transcripts, never quoted
#
# A command runs with no terminal attached, which is why nothing is in colour.
set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE='~'
lab() { bash "$COURSE/lab.sh" "$@"; }
at() { HERE=$1; quiet "mkdir -p $(dir)"; }
dir() { [ "$HERE" = '~' ] && echo '$HOME' || echo "${HERE/#\~/\$HOME}"; }
lesson() { echo "$COURSE/lessons/$1"; }
save() { # save LESSON-ID/section.md FILE DEST [N]
  python3 "$COURSE/lab/extract.py" "$COURSE/lessons/$1" "$2" "${4:-1}" \
    | lab as "mkdir -p \"\$(dirname $3)\" && cat > $3"
}
run() {
  printf 'ana@vm:%s$ %s\n' "$HERE" "$1"
  lab as "cd $(dir) && export COLUMNS=100 NO_COLOR=1 && { $1 ; }" 2>&1 || true
}
quiet() { lab as "cd $(dir) && { $1 ; }" >/dev/null 2>&1 || true; }
prebuild() { lab prebuild "$(lab as "cd $(dir) && pwd")"; }
block() { printf '##### %s\n' "$1"; }
