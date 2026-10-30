# Sourced by lab.sh and by every lesson's captures.sh: the few functions that
# turn a script into the transcripts a lesson quotes. Not for the student.
#
#   emulators_up            a fresh, empty fake-gcs-server on 4443 and Pub/Sub
#                           emulator on 8085, as lesson 1 starts them
#   emulators_down          both containers stopped (they are --rm)
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
# the recording machine's own agent variables, which some tools notice
for v in $(compgen -e | grep -E '^(CLAUDE|AI_AGENT|CCR_)'); do unset "$v"; done
# The recording machine reaches the internet through a proxy, and gcloud is
# configured for it with CLOUDSDK_PROXY_*, which it applies even to localhost.
# Every gcloud call in this course goes to an emulator on localhost, so the
# gcloud-only variables are dropped; HTTPS_PROXY, which everything else uses
# for the internet, is left alone.
unset CLOUDSDK_PROXY_TYPE CLOUDSDK_PROXY_ADDRESS CLOUDSDK_PROXY_PORT
# and the recording machine's own Google token, which a student does not have
unset CLOUDSDK_AUTH_ACCESS_TOKEN GOOGLE_OAUTH_ACCESS_TOKEN GOOGLE_APPLICATION_CREDENTIALS
[ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"
# as after `source venv/bin/activate`: the environment's python3 comes first
export PATH="$HOME/gcp/venv/bin:$HOME/.local/bin:$PATH"

GCS_IMAGE=fsouza/fake-gcs-server:1.52.2
EMU_IMAGE=gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators

emulators_down() { docker rm -f gcs pubsub > /dev/null 2>&1 || true; }
emulators_up() {
  emulators_down
  docker run -d --rm --name gcs -p 4443:4443 "$GCS_IMAGE" \
    -scheme http -backend memory -public-host localhost:4443 > /dev/null
  docker run -d --rm --name pubsub -p 8085:8085 "$EMU_IMAGE" \
    gcloud beta emulators pubsub start --project=planner-dev --host-port=0.0.0.0:8085 > /dev/null
  for _ in $(seq 120); do
    curl -s -o /dev/null http://localhost:4443/storage/v1/b \
      && curl -s -o /dev/null http://localhost:8085/ && return 0
    sleep 0.5
  done
  echo "emulators did not start"; docker logs gcs; docker logs pubsub; exit 1
}

student_env() {
  export CLOUDSDK_CORE_PROJECT=planner-dev
  export CLOUDSDK_AUTH_DISABLE_CREDENTIALS=true
  export CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE=http://localhost:4443/storage/v1/
  export CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB=http://localhost:8085/
  export STORAGE_EMULATOR_HOST=http://localhost:4443
  export PUBSUB_EMULATOR_HOST=localhost:8085
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
    elif lang in ('json', '') and before.endswith('`' + want + '`:'):
        found.append(body)
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one block for {want}, found {len(found)}')
sys.stdout.write(found[0])
PY
}
