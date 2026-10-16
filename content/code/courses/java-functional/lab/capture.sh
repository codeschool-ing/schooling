# Sourced by every lesson's captures.sh: the prompt, and the one way a file
# reaches ana's machine.
#
#   at DIR          the directory, under ~ana, that the next lines work in;
#                   emptied first, so a lesson starts from nothing
#   on CMD          ana typed CMD in that directory, and what it printed
#   home CMD        ana typed CMD in her home directory
#   src FILE MD [AS]
#                   write FILE into that directory, taken from MD (a section
#                   of this lesson, or ../<lesson>/<section>.md): the
#                   annotated example naming FILE, or the plain fence whose
#                   first line names it; AS takes the fence that names AS
#                   instead, for a copy saved under another name. A file no
#                   lesson shows cannot be written, so no transcript leans on
#                   a program the student was never given
#   put FILE        stdin becomes FILE, refused unless some lesson of the
#                   course shows exactly that text as a fence
#   block NAME      a marker between transcripts, never quoted
#   quiet CMD       a step of the lab's, its output shown only if it fails
#
# Every command runs with stdin closed and gives up after five minutes.
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LESSON=$(pwd)
LAB_SH=${LAB_SH:-$COURSE/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
DIR=
at() { DIR=$1; lab fresh "$DIR"; }
on() { printf 'ana@vm:~/%s$ %s\n' "$DIR" "$*"; lab exec "$DIR" "timeout 300 bash -c $(printf '%q' "$*") 2>&1 < /dev/null" || true; }
home() { printf 'ana@vm:~$ %s\n' "$*"; lab exec . "timeout 300 bash -c $(printf '%q' "$*") 2>&1 < /dev/null" || true; }
src() {
  local text; text=$(python3 "$COURSE/lab/fences.py" named "$LESSON/$2" "${3:-$(basename "$1")}"; printf x) || exit 1
  text=${text%x}
  printf '%s' "$text" | lab put "$DIR/$1"
}
put() {
  local text; text=$(cat; printf x); text=${text%x}
  printf '%s' "$text" | python3 "$COURSE/lab/fences.py" has "$COURSE" || exit 1
  printf '%s' "$text" | lab put "$DIR/$1"
}
block() { printf '##### %s\n' "$1"; }
quiet() { lab exec "$DIR" "$*" > /tmp/jf-capture-step.log 2>&1 || { cat /tmp/jf-capture-step.log; exit 1; }; }
