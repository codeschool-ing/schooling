# Sourced by every lesson's captures.sh. Prints a transcript the way Ana's
# terminal on the lab shows it: the prompt, what was typed, what came back.
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
export COMPOSE_PROGRESS=plain DOCKER_CLI_HINTS=false
SCRIPT=$(realpath "$0")
LAB=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lab.sh
block() { printf '##### %s\n' "$1"; }
here() { pwd | sed "s|^$HOME|~|"; }
run() { printf 'ana@lab:%s$ %s\n' "$(here)" "$*"; bash -c "$*" 2>&1; }
# a command typed in a second terminal: shown, not run here
shown() { printf 'ana@lab:%s$ %s\n' "$(here)" "$*"; }
# A captures.sh defines one function per block, cap_<name>, and ends with
# `captures "$@"`: with no arguments every block runs in the order defined,
# with names only those (each block then has to set up what it needs).
captures() {
  local names=("$@")
  [ ${#names[@]} -eq 0 ] && mapfile -t names < <(grep -o '^cap_[a-z0-9_]*' "$SCRIPT" | sed 's/^cap_//')
  for n in "${names[@]}"; do n=${n//-/_}; block "${n//_/-}"; "cap_$n"; done
}
