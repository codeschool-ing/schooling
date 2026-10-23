# Shared by every lesson's captures.sh. Sourced, never run.
#
# A line that starts with ana@dev:~/planner$ is what ana typed, and what came
# back. CWD is the folder under her home the next command runs in.
LAB_SH=${LAB_SH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lab.sh}
LESSON_DIR=$(pwd)
SHOWN=$(mktemp -d)
CWD=planner
lab() { bash "$LAB_SH" "$@"; }
prompt() { if [ -z "$CWD" ]; then printf 'ana@dev:~$ '; else printf 'ana@dev:~/%s$ ' "$CWD"; fi; }
here() { if [ -z "$CWD" ]; then echo '~'; else echo "~/$CWD"; fi; }
on() { prompt; printf '%s\n' "$*"; lab exec ana "cd $(here) && $*" 2>&1 || true; }
# What a program printed, without the command.
run() { lab exec ana "cd $(here) && $*" 2>&1 || true; }
# A file ana wrote. The lesson shows it in full, and shown.mjs holds it to that.
put() {
  local f=$1 body n
  body=$(cat)
  n=$(ls "$SHOWN" | wc -l)
  printf '%s\n' "$body" > "$SHOWN/$n-$(basename "$f")"
  printf '#####F %s\n%s\n#####E\n' "$f" "$body"
  lab exec ana "cd $(here) && mkdir -p \"\$(dirname '$f')\" && cat > '$f'" <<<"$body"
}
# A file ana wrote that an earlier lesson already showed, or that this lesson
# shows only in part: it is NOT checked against the prose, so each use says why.
quietly_put() {
  local f=$1 body
  body=$(cat)
  lab exec ana "cd $(here) && mkdir -p \"\$(dirname '$f')\" && cat > '$f'" <<<"$body"
}
block() { printf '##### %s\n' "$1"; }
# A server left running in a second terminal, and what it printed once it was up.
serve() {
  local port=$1; shift
  lab serve "cd $(here) && $*"
  for _ in $(seq 120); do
    curl -s -o /dev/null "http://localhost:$port/" 2>/dev/null && break
    sleep 0.25
  done
  sleep 0.5
}
served() { cat /run/rtlab-server.out; }
stop() { lab stop; }
finish() {
  block _end
  stop
  node "$(dirname "$LAB_SH")/lab/shown.mjs" "$LESSON_DIR" "$SHOWN"/* || exit 1
  rm -rf "$SHOWN"
}
