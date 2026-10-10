# Sourced by every lesson's captures.sh. The author's, never the student's.
#
#   vm 'command'          the prompt, the command, and what it printed, in ~/work
#   home 'command'        the same, from ~ (the prompt says ~)
#   term2 NAME 'command'  start a command in a second terminal and leave it running
#   stop2 NAME [SIG]      press Ctrl-C there (SIGINT unless told) and print that terminal
#   wait2 NAME            let it finish by itself, and print that terminal
#   put NAME              a file the student saved in ~/work, from stdin (shown in the lesson)
#   block NAME            a marker between transcripts; the lesson quotes one block per fence
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
run() { lab run "$1" 2>&1; }
vm() { printf 'ubuntu@stream:~/work$ %s\n' "$1"; run "$1" || true; }
home() { printf 'ubuntu@stream:~$ %s\n' "$1"; lab run "cd ~ && $1" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
put() { lab run "cat > ~/work/$1"; }
declare -A T2PID
term2() {
  local f=/tmp/term2-$1
  printf 'ubuntu@stream:~/work$ %s\n' "$2" > "$f"
  setsid env --default-signal=INT bash "$LAB_SH" run "exec $2" >> "$f" 2>&1 < /dev/null &
  T2PID[$1]=$!
  sleep "${3:-2}"
}
stop2() {
  local pid=${T2PID[$1]} sid t
  sid=$(ps -o sid= -p "$pid" | tr -d ' ')
  pkill -"${2:-INT}" -s "$sid" -u ubuntu 2>/dev/null || true
  for t in $(seq 1 40); do pgrep -s "$sid" -u ubuntu >/dev/null || break; sleep 0.5; done
  kill -- -"$sid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  cat "/tmp/term2-$1"; rm -f "/tmp/term2-$1"
}
wait2() { wait "${T2PID[$1]}" 2>/dev/null || true; cat "/tmp/term2-$1"; rm -f "/tmp/term2-$1"; }
shown() { printf 'ubuntu@stream:~/work$ %s\n' "$1"; }   # a command as typed, before what it prints is shown
