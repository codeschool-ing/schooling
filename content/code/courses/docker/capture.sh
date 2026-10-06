# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes.
#
# A captures.sh re-runs itself inside the lab (lab.sh run): a clean daemon, a
# fresh /home/ana with ~/shelf in it, ana's environment. Then:
#
#   run 'command'        print ana's prompt and the command, then run it and
#                        print everything it wrote, stdout and stderr together
#   quiet 'command'      run without showing: the lab's own housekeeping
#   put FILE <<'EOF'     a file ana wrote, from stdin. Its content is shown in
#                        the lesson as a fence of its own, and is printed here
#                        between "file:" markers so it is quoted from the run
#   block NAME           a marker between transcripts, never quoted
#
# Two things differ from a terminal, both on purpose. A prompt is printed by
# this script rather than by a shell, from the directory the command ran in.
# And a command is run with no terminal attached, which is why `docker build`
# prints its plain progress and `docker pull` its line-by-line one: the same
# words a pipeline's log shows.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -z "${IN_LAB:-}" ]; then
  exec sudo LAB_IMAGES="${LAB_IMAGES:-}" bash "$COURSE/lab.sh" run bash "$(realpath "$0")" "$@"
fi
cd /home/ana || exit 1

prompt() { # keeps $?, so a command can read the status of the one before it
  local rc=$? here=${PWD/#\/home\/ana/\~}
  printf 'ana@vm:%s$ %s\n' "$here" "$1"
  return $rc
}
run() { # returns what the command returned, so `run 'echo $?'` can show it
  prompt "$1"
  eval "$1" 2>&1 </dev/null
}
quiet() { eval "$1" >/dev/null 2>&1 </dev/null || true; }
put() { # also printed between file markers, so the lesson quotes the file
  # that was used rather than a copy of it
  mkdir -p "$(dirname "$1")" && cat > "$1"
  printf '##### file:%s\n' "${PWD/#\/home\/ana/\~}/$1"; cat "$1"; printf '##### end-file\n'
}
block() { printf '##### %s\n' "$1"; }
