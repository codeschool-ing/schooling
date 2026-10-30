# Sourced by lab.sh and by every lesson's captures.sh: the few functions that
# turn a script into the transcripts a lesson quotes. Not for the student.
#
#   azurite_up              a fresh, empty Azurite on 10000-10002 (removed at exit)
#   kusto_up                a fresh Kusto emulator on 8080 with an empty database
#                           `shop`, as lesson 9 has the student start it
#   student_env             the variables lesson 1 has the student export
#   run 'command'           print ana's prompt and the command, then run it
#                           and print stdout and stderr together
#   quiet 'command'         run without showing: the lab's own housekeeping
#   put FILE <<'EOF'        a file ana wrote. The lesson shows it in a fence
#                           of its own; here it is printed between markers
#   block NAME              a marker between transcripts, never quoted
#   fence MD N              run the Nth ```sh fence of a lesson file, as it
#                           stands, and stop the capture if it fails
#   from_lesson MD FILE     print the fenced block of MD whose first line is
#                           the comment naming FILE (or, for JSON, which has
#                           no comments, whose preceding line ends `FILE`:),
#                           byte for byte, so the program a capture runs is
#                           the one the student reads
#
# The prompt is printed by this script, from the directory the command ran in,
# as ana@laptop. Every capture runs with TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana
# the recording machine's own agent variables, which no tool here should see
for v in $(compgen -e | grep -E '^(CLAUDE|AI_AGENT|CCR_)'); do unset "$v"; done
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"
# as after `source venv/bin/activate`, with Terraform and Bicep where the lessons put them
export PATH="$HOME/azure/venv/bin:$HOME/.local/bin:$HOME/.azure/bin:$PATH"

AZURITE_IMAGE=mcr.microsoft.com/azure-storage/azurite:3.37.0
KUSTO_IMAGE=mcr.microsoft.com/azuredataexplorer/kustainer-linux:2026.10.29.1806-2643-0ef1614-master

azurite_up() {
  docker rm -f azurite > /dev/null 2>&1
  docker run -d --name azurite -p 10000-10002:10000-10002 "$AZURITE_IMAGE" > /dev/null || exit 1
  for _ in $(seq 40); do curl -s -o /dev/null http://127.0.0.1:10000/ && return 0; sleep 0.25; done
  echo "azurite did not start"; exit 1
}

kusto_up() {
  docker rm -f kusto > /dev/null 2>&1
  docker run -d --name kusto -e ACCEPT_EULA=Y -m 4g -p 8080:8080 "$KUSTO_IMAGE" > /dev/null || exit 1
  for _ in $(seq 120); do
    curl -s -o /dev/null -X POST http://127.0.0.1:8080/v1/rest/mgmt \
      -H 'Content-Type: application/json' -d '{"csl":".show version"}' && break
    sleep 1
  done
  curl -s -o /dev/null -X POST http://127.0.0.1:8080/v1/rest/mgmt -H 'Content-Type: application/json' \
    -d '{"csl":".create database shop volatile"}' || { echo "kusto did not start"; exit 1; }
}

lab_down() { docker rm -f azurite kusto > /dev/null 2>&1 || true; }

student_env() {
  export AZURE_STORAGE_CONNECTION_STRING=UseDevelopmentStorage=true
  export AZURE_CORE_COLLECT_TELEMETRY=false
}

prompt() { printf 'ana@laptop:%s$ %s\n' "${PWD/#$HOME/\~}" "$1"; }
run() { prompt "$1"; eval "$1" 2>&1 < /dev/null; return 0; }
quiet() { eval "$1" > /dev/null 2>&1 < /dev/null || true; }
put() {
  mkdir -p "$(dirname "$1")" && cat > "$1"
  printf '##### file:%s\n' "$1"; cat "$1"; printf '##### end-file\n'
}
block() { printf '##### %s\n' "$1"; }

fence() {
  local md=$1 n=$2 tmp
  tmp=$(mktemp)
  python3 - "$md" "$n" > "$tmp" <<'PY' || { rm -f "$tmp"; exit 1; }
import re, sys
fences = re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
n = int(sys.argv[2])
if not 1 <= n <= len(fences):
    sys.exit(f'{sys.argv[1]}: no sh fence number {n} (there are {len(fences)})')
sys.stdout.write(fences[n - 1])
PY
  ( cd "$HOME" && bash -e "$tmp" ) > "$tmp.log" 2>&1 \
    || { echo "fence $n of $md failed:"; cat "$tmp.log"; rm -f "$tmp" "$tmp.log"; exit 1; }
  rm -f "$tmp" "$tmp.log"
}

from_lesson() {
  python3 - "$1" "$2" <<'PY'
import json, re, sys
text, want = open(sys.argv[1]).read(), sys.argv[2]
found = []
for m in re.finditer(r'^```([a-z-]*)\n(.*?)^```$', text, re.S | re.M):
    lang, body = m.group(1), m.group(2)
    before = text[:m.start()].rstrip().rsplit('\n', 1)[-1]
    if lang == 'schooling-example':
        ex = json.loads(body)
        if ex.get('file') == want:
            found.append(''.join(p['code'] for p in ex['parts']))
    elif body.split('\n', 1)[0].lstrip('#/ ').startswith(want):
        found.append(body)
    elif lang == 'json' and before.endswith('`' + want + '`:'):
        found.append(body)
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one block for {want}, found {len(found)}')
sys.stdout.write(found[0])
PY
}
