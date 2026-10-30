# Sourced by lab.sh and by the lessons' captures.sh. Not for the student, who
# has none of it.
#
# THE PROGRAMS AND FILES A CAPTURE USES ARE READ OUT OF THE LESSON THAT SHOWS
# THEM, so the two cannot drift apart: there is no second copy to edit.
#
#   example FILE NAME DEST   writes DEST from the schooling-example in FILE whose
#                            "file" is NAME: its code parts, in order
#   fence FILE N             prints the Nth ```sh fence of FILE (counted from 1)
#   file_fence FILE NAME     prints the fence that follows the line `NAME`: in
#                            FILE, for a small file shown whole in a lesson
#   run CMD                  prints the prompt and CMD, then runs CMD; what the
#                            terminal would show is what is printed, so a line a
#                            progress meter rewrites with \r keeps its last state
#   block NAME               a marker line the author copies transcripts by
#   services NAME...         the emulators a capture needs, started fresh and
#                            empty, and waited for until each one answers

AZURE_DATA_COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSONS="$AZURE_DATA_COURSE/lessons"

example() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
blocks = re.findall(r'^```schooling-example\n(.*?)\n```$', text, re.S | re.M)
found = [b for b in (json.loads(x) for x in blocks) if b.get('file') == sys.argv[2]]
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one example for {sys.argv[2]}, found {len(found)}')
open(sys.argv[3], 'w').write(''.join(p['code'] for p in found[0]['parts']))
PY
}

fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
fences = re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
n = int(sys.argv[2])
if not 1 <= n <= len(fences):
    sys.exit(f'{sys.argv[1]}: no sh fence number {n} (there are {len(fences)})')
sys.stdout.write(fences[n - 1])
PY
}

file_fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r'`' + re.escape(sys.argv[2]) + r'`:\n\n```[a-z]*\n(.*?)^```$', text, re.S | re.M)
if not m:
    sys.exit(f'{sys.argv[1]}: no fence introduced by `{sys.argv[2]}`:')
sys.stdout.write(m.group(1))
PY
}

PROMPT_DIR=${PROMPT_DIR:-'~/azure'}
run() {
  printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"
  bash -c "$*" 2>&1 | sed 's/.*\r//' || true
}
block() { printf '##### %s\n' "$1"; }

# The emulators, as the student starts them with `docker compose`. A capture
# always starts from empty ones: whatever an earlier capture left is taken
# down with its volumes first. Readiness is waited for here and not shown,
# because a student sees it as the time before their first command works.
services() {
  ( cd "$HOME/azure" && docker compose --profile '*' down -v --remove-orphans ) > /dev/null 2>&1
  local profiles=() s
  for s in "$@"; do [ "$s" = azurite ] || profiles+=(--profile "$s"); done
  ( cd "$HOME/azure" && docker compose "${profiles[@]}" up -d ) > "$HOME/.compose.log" 2>&1 \
    || { echo "compose did not start:"; cat "$HOME/.compose.log"; return 1; }
  for s in azurite "$@"; do
    for _ in $(seq 240); do
      case $s in
        azurite) curl -s -o /dev/null http://127.0.0.1:10000/ && break ;;
        cosmos) curl -s -o /dev/null http://127.0.0.1:8081/ && sleep 8 && break ;;
        sql) docker exec azure-sql-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa \
               -P Quitanda-Lab-2026 -C -Q 'SELECT 1' > /dev/null 2>&1 && break ;;
        eventhubs) docker logs azure-eventhubs-1 2>&1 | grep -q 'Successfully Up' && break ;;
        postgres) docker exec azure-postgres-1 pg_isready -q -U postgres 2>/dev/null && sleep 2 && break ;;
        redis) docker exec azure-redis-1 redis-cli ping > /dev/null 2>&1 && break ;;
      esac
      sleep 0.5
    done
  done
}
services_down() {
  ( cd "$HOME/azure" && docker compose --profile '*' down -v --remove-orphans ) > /dev/null 2>&1
}
