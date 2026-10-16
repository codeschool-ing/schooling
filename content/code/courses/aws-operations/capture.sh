# Sourced by lab.sh and by every lesson's captures.sh: the few functions that
# turn a script into the transcripts a lesson quotes. Not for the student.
#
#   moto_up [ENV=VALUE...]  a fresh, empty moto on 127.0.0.1:4567 (killed at
#                           exit), with any environment the lesson gives it
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
unset AWS_PROFILE AWS_REGION AWS_SESSION_TOKEN
# the recording machine's own agent variables, which some tools (the CDK) notice
for v in $(compgen -e | grep -E '^(CLAUDE|AI_AGENT|CCR_)'); do unset "$v"; done
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"
# as after `source venv/bin/activate`: the environment's python3 comes first
export PATH="$HOME/.local/bin:$HOME/aws/venv/bin:$PATH"
[ -f /opt/awsops/terraformrc ] && export TF_CLI_CONFIG_FILE=/opt/awsops/terraformrc

MOTO_PID=
moto_up() {
  local log=${MOTO_LOG:-/var/tmp/awsops-moto.log} d c
  moto_down
  # a moto left over from an earlier run would answer instead, with its state
  for d in /proc/[0-9]*; do
    c=$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null) || continue
    case "$c" in *bin/moto_server\ -p\ 4567*) kill "${d#/proc/}" 2>/dev/null ;; esac
  done
  for _ in $(seq 40); do curl -s -o /dev/null http://127.0.0.1:4567/ || break; sleep 0.25; done
  env "$@" setsid "$HOME/aws/venv/bin/moto_server" -p 4567 > "$log" 2>&1 < /dev/null &
  MOTO_PID=$!
  for _ in $(seq 80); do
    kill -0 "$MOTO_PID" 2>/dev/null || { echo "moto exited"; cat "$log"; exit 1; }
    curl -s -o /dev/null http://127.0.0.1:4567/ && return 0
    sleep 0.25
  done
  echo "moto did not start"; cat "$log"; exit 1
}
moto_down() { [ -n "$MOTO_PID" ] && kill "$MOTO_PID" 2>/dev/null && wait "$MOTO_PID" 2>/dev/null; MOTO_PID=; }
trap moto_down EXIT

student_env() {
  export AWS_ENDPOINT_URL=http://localhost:4567
  export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
  export AWS_DEFAULT_REGION=sa-east-1
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
