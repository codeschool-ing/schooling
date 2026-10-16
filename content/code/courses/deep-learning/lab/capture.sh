# Sourced by every lesson's captures.sh. The author's, never the student's.
#
#   on 'COMMAND'     print the prompt and COMMAND, then what it printed, run as
#                    ana in ~/dl with the virtual environment active
#   bare 'COMMAND'   the same in a terminal where it was never activated
#   use NAME...      write each NAME into ~/dl as the lessons show it
#   quiet 'COMMAND'  run COMMAND in ~/dl and print nothing (staging)
#   block NAME       start the capture block NAME, which a lesson pastes
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
COURSE=$(cd "$(dirname "$LAB_SH")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~/dl$ %s\n' "$*"; lab exec "$*" 2>&1 </dev/null || true; }
bare() {
  printf 'ana@vm:~/dl$ %s\n' "$*"
  (cd /home/ana/dl && env -i HOME=/home/ana USER=ana PATH=/opt/dl-share/bin:/usr/local/bin:/usr/bin:/bin LANG=C.UTF-8 \
    bash -c "$*" 2>&1 </dev/null) || true
}
quiet() { lab exec "$*" >/dev/null 2>&1 </dev/null; }
use() {
  local f
  for f in "$@"; do
    python3 "$COURSE/lab/shown.py" "$COURSE" "$f" "${L:-}" > "/home/ana/dl/$f" || exit 1
  done
}
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/dl-capture.lock; flock 9
