# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes.
#
# A captures.sh runs as root on the laptop lab.sh describes, with HOME=/home/ana,
# and prints every transcript it makes under a line `##### NAME`. The lesson's
# fences are copied from that output, byte for byte.
#
#   run 'command'       print ana's prompt and the command, then run it and print
#                       everything it wrote, stdout and stderr together
#   quiet 'command'     run without showing: the lab's own housekeeping, such as
#                       waiting for a rollout before the next command
#   block NAME          the marker in front of a transcript
#   shown MD NAME DEST  write the file a lesson shows under the line that names
#                       `NAME` and ends in a colon into DEST, byte for byte, so
#                       that what the student copies is what the capture runs
#   at DATE cmd...      run cmd with git's author and committer dates fixed, so
#                       a commit's hash is the same on every run
#
# The prompt is printed by this script, from the directory the command ran in,
# as ana@laptop.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export HOME=/home/ana USER=ana TZ=America/Sao_Paulo LC_ALL=C.UTF-8
export PATH=/opt/gitops/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export KUBECONFIG=/home/ana/.kube/config
export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org
mkdir -p /home/ana
HOST=${HOST:-laptop}

lab() { bash "$COURSE/lab.sh" "$@"; }
prompt() { printf 'ana@%s:%s$ %s\n' "$HOST" "${PWD/#\/home\/ana/\~}" "$1"; }
run() { prompt "$1"; eval "$1" 2>&1 </dev/null; return 0; }
quiet() { eval "$1" >/dev/null 2>&1 </dev/null || true; }
block() { printf '##### %s\n' "$1"; }
at() { local d=$1; shift; GIT_AUTHOR_DATE=$d GIT_COMMITTER_DATE=$d "$@"; }
shown() {
  local out
  out=$(awk -v name="\`$2\`" '
    f == 0 && index($0, name) && /:$/ { f = 1; next }
    f == 1 && /^```/ { f = 2; next }
    f == 2 && /^```$/ { exit }
    f == 2 { print }' "$1") && [ -n "$out" ] || { echo "##### $1 shows no $2" >&2; exit 1; }
  mkdir -p "$(dirname "$3")"
  printf '%s\n' "$out" > "$3"
}
# settle NAMESPACE...: wait until no pod there is terminating. bulletin's httpd
# runs as PID 1 and ignores SIGTERM, so an old pod lingers for its thirty-second
# grace period after every rollout, and a pod listing taken in that window shows
# the last rollout instead of the change being made.
settle() {
  local ns i
  for ns in "$@"; do
    for i in $(seq 60); do
      kubectl -n "$ns" get pods 2>/dev/null | grep -q Terminating || break
      sleep 2
    done
  done
}
