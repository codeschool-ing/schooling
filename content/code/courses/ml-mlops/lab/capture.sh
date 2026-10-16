# Sourced by every lesson's captures.sh: the prompts, and the one way a file
# reaches ana's machine.
#
#   on CMD      ana typed CMD in ~/ml, with the environment active
#   home CMD    ana typed CMD in ~, with the environment active
#   bare CMD    ana typed CMD in ~ in a new terminal, without the environment
#   put FILE    stdin becomes ~/ml/FILE, refused unless some lesson shows
#               exactly that text as a fence, so no lesson can lean on a file
#               the student was never shown
#   stage FILE MD   ~/ml/FILE becomes the program lesson MD shows whole,
#               read out of the lesson rather than out of a copy of it
#   block NAME  a marker between transcripts: NAME is the section the
#               transcript after it belongs to, never quoted
#   quiet CMD   a step of the lab's, its output shown only if it fails
#
# Every command runs with stdin closed, as a terminal's would be when nobody
# types into it, and gives up after an hour.
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAB_SH=${LAB_SH:-$COURSE/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
run_as() { lab exec "timeout 3600 bash -c $(printf '%q' "$*")"; }
on() { printf 'ana@dev:~/ml$ %s\n' "$*"; run_as "$*" 2>&1 < /dev/null || true; }
home() { printf 'ana@dev:~$ %s\n' "$*"; IN_HOME=1 run_as "$*" 2>&1 < /dev/null || true; }
bare() { printf 'ana@dev:~$ %s\n' "$*"; IN_HOME=1 BARE=1 run_as "$*" 2>&1 < /dev/null || true; }
put() {
  local text; text=$(cat; printf x); text=${text%x}
  printf '%s' "$text" | python3 "$COURSE/lab/fences.py" has "$COURSE" || exit 1
  printf '%s' "$text" | lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"
}
stage() {  # stage FILE LESSON_MD: the annotated example or plain fence naming FILE
  local md=$COURSE/lessons/$2
  { python3 "$COURSE/lab/fences.py" example "$md" "$1" 2>/dev/null \
      || python3 "$COURSE/lab/fences.py" named "$md" "$1"; } | put "$1"
}
block() { printf '##### %s\n' "$1"; }
quiet() { "$@" > /tmp/mlops-capture-step.log 2>&1 || { cat /tmp/mlops-capture-step.log; exit 1; }; }
