# Sourced by every lesson's captures.sh: the functions that turn a script into
# the transcripts a lesson quotes.
#
# A captures.sh runs as root on the machine lab.sh describes. Every command it
# shows runs as ana, in ONE long-lived bash of hers, so `cd`, `export` and an
# activated virtual environment carry from one command to the next exactly as
# they do in a terminal. Then:
#
#   run 'command'      print ana's prompt and the command, run it, and print
#                      everything it wrote, stdout and stderr together
#   quiet 'command'    run it in the same shell without showing it: the lab's
#                      housekeeping, such as waiting for a container
#   put PATH <<'EOF'   write a file as ana, from stdin, relative to her
#                      current directory. Its content is printed between
#                      "##### file:" markers so the lesson quotes it from the run
#   block NAME         a marker between transcripts, never quoted
#   lab ARGS...        lab.sh, for `lab project N` and the rest
#
# The prompt is printed here rather than by a shell: `ana@vm:~/linkbox$ `,
# with the environment's name in brackets in front while one is active.

set -uo pipefail
# The lab is one machine and one user: a second capture running at the same
# time would rebuild ~/linkbox under this one. Wait for the lab to be free.
if [ -z "${SP_LOCKED:-}" ]; then
  exec 9>/var/lock/secure-pipeline-lab.lock
  flock 9
  export SP_LOCKED=1
fi
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
lab() { bash "$COURSE/lab.sh" "$@"; }

_US=$'\037'
_start_shell() {
  coproc ANA { bash "$COURSE/lab.sh" as bash --noprofile --norc 2>&1; }
  printf 'cd ~; PS1=; PS2=\n' >&"${ANA[1]}"
}
_start_shell

_send() { # COMMAND: run in ana's shell, print its output, set _venv and _dir
  local cmd=$1 line
  printf '%s\n' "{ $cmd
} </dev/null 2>&1; printf '\\n${_US}END %s %s\\n' \"\${VIRTUAL_ENV_PROMPT:-}\" \"\$PWD\"" >&"${ANA[1]}"
  local prev='' have=0
  while IFS= read -r -t 900 line <&"${ANA[0]}"; do
    if [[ $line == "${_US}END "* ]]; then
      line=${line#"${_US}END "}
      _venv=${line%% *}
      _dir=${line#* }
      # the marker is preceded by a newline of its own: drop the empty line it
      # makes after output that already ended in one
      [ "$have" = 1 ] && [ -n "$prev" ] && printf '%s\n' "$prev"
      return 0
    fi
    [ "$have" = 1 ] && printf '%s\n' "$prev"
    prev=$line have=1
  done
  echo "##### the command timed out: $cmd" >&2
  return 1
}
_venv='' _dir=/home/ana

prompt() {
  local here=${_dir/#\/home\/ana/\~} pre=''
  [ -n "$_venv" ] && pre="($_venv) "
  printf '%sana@vm:%s$ %s\n' "$pre" "$here" "$1"
}
run() { prompt "$1"; _send "$1"; }
quiet() { _send "$1" >/dev/null; }
put() {
  local path=$1 body
  body=$(cat; printf x) && body=${body%x}
  printf '%s' "$body" | bash "$COURSE/lab.sh" as sh -c "cd '$_dir' && mkdir -p \"\$(dirname '$path')\" && cat > '$path'"
  printf '##### file:%s\n%s##### end-file\n' "$path" "$body"
}
block() { printf '##### %s\n' "$1"; }
place() { # MD PATH: the file the lesson MD shows whole as PATH, written where
  # it belongs (PATH relative to ~/linkbox, or starting with ~/), so the
  # capture runs exactly what the student copies
  local md=$1 path=$2 dest
  case $path in "~/"*) dest="/home/ana/${path#\~/}" ;; *) dest="/home/ana/linkbox/$path" ;; esac
  python3 "$COURSE/lab/shown.py" "$COURSE/$md" "$path" |
    bash "$COURSE/lab.sh" as sh -c "mkdir -p \"\$(dirname '$dest')\" && cat > '$dest'"
}
