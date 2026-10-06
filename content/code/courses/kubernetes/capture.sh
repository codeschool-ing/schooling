# Sourced by every lesson's captures.sh: the few functions that turn a script
# into the transcripts a lesson quotes.
#
# A captures.sh runs as root on the laptop lab.sh describes, with HOME=/home/ana
# and kubectl pointed at ana's kubeconfig. Most start with `fresh`, which
# deletes whatever cluster is there and makes a new one, so a lesson never
# depends on what the one before it left behind. Then:
#
#   run 'command'        print ana's prompt and the command, then run it and
#                        print everything it wrote, stdout and stderr together
#   quiet 'command'      run without showing: the lab's own housekeeping, such
#                        as waiting for a rollout before the next command
#   put FILE <<'EOF'     a file ana wrote, from stdin. Its content is shown in
#                        the lesson as a fence of its own, and is printed here
#                        between "file:" markers so it is quoted from the run
#   block NAME           a marker between transcripts, never quoted
#
# The prompt is printed by this script rather than by a shell, from the
# directory the command ran in, as ana@laptop. Names Kubernetes invents — the
# random tail of a pod's name, a ClusterIP, a pod's address — differ on every
# run, and the lessons quote them from the run that is published.

set -uo pipefail
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export HOME=/home/ana KUBECONFIG=/home/ana/.kube/config TZ=America/Sao_Paulo LC_ALL=C.UTF-8
export PATH=/opt/k8s/bin:$PATH
mkdir -p /home/ana/shop && cd /home/ana/shop || exit 1
HOST=${HOST:-laptop}

lab() { bash "$COURSE/lab.sh" "$@"; }
fresh() { lab up "$@" >/dev/null 2>&1 || { echo "##### the cluster did not come up" >&2; exit 1; }; }
prompt() {
  local here=${PWD/#\/home\/ana/\~}
  printf 'ana@%s:%s$ %s\n' "$HOST" "$here" "$1"
}
run() {
  prompt "$1"
  eval "$1" 2>&1 </dev/null
  return 0
}
quiet() { eval "$1" >/dev/null 2>&1 </dev/null || true; }
put() {
  mkdir -p "$(dirname "$1")" && cat >"$1"
  printf '##### file:%s\n' "${PWD/#\/home\/ana/\~}/$1"; cat "$1"; printf '##### end-file\n'
}
block() { printf '##### %s\n' "$1"; }
