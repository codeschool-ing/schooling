# Sourced by every lesson's captures.sh. The author's, never the student's.
#
#   on 'COMMAND'     print the prompt and COMMAND, then what it printed, run as
#                    ana in ~/rag with env.sh, exactly as a student's terminal
#   bare 'COMMAND'   the same in a terminal that never ran env.sh
#   use NAME...      write each NAME into ~/rag as the lessons show it
#   block NAME       start the capture block NAME, which a lesson pastes
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
COURSE=$(cd "$(dirname "$LAB_SH")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@vm:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 </dev/null || true; }
bare() {
  printf 'ana@vm:~/rag$ %s\n' "$*"
  env -i HOME=/home/ana USER=ana PATH=/opt/rag-share/bin:/usr/local/bin:/usr/bin:/bin LANG=C.UTF-8 \
    bash -c "cd /home/ana/rag && $*" 2>&1 || true
}
use() {
  local f
  for f in "$@"; do
    python3 "$COURSE/lab/shown.py" "$COURSE" "$f" "${L:-}" > "/home/ana/rag/$f" || exit 1
  done
}
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/rag.
exec 9>/var/tmp/rag-capture.lock; flock 9
