# Sourced by the lessons' captures.sh. Not for the student, who has none of it.
#
# THE STUDENT'S LAB IS BUILT BY LESSON 1, OUT OF ITS OWN TEXT, and every other
# lesson is recorded in that lab: the home directory lesson 1's captures.sh
# filled, with the Google Cloud CLI in ~/.local/google-cloud-sdk, Terraform in
# ~/.local/bin, a Python virtual environment in ~/gcp/venv, the lab's own gcloud
# configuration in ~/gcp/gcloud and ~/gcp/env.sh.
#
# WHAT IS STAGED, and why, for every lesson (each captures.sh adds its own):
#   - ana's home is /home/ana on the recording machine, and HOME points at it.
#     There is no user ana: the files belong to root. Nothing quoted prints an
#     owner;
#   - every CLOUDSDK_* and GOOGLE_* variable the recording machine's
#     environment carried is unset before ~/gcp/env.sh is read, so nothing of
#     the author's reaches the tools;
#   - the recording machine reaches the internet only through an HTTPS proxy
#     with its own certificate authority. curl and Terraform read HTTPS_PROXY
#     and the system's certificates, and print nothing about either. gcloud
#     does not, so a block that sends gcloud to Google calls `net` first, which
#     gives gcloud the proxy and the certificate through CLOUDSDK_PROXY_* and
#     CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE. No block that prints gcloud's
#     properties runs after `net`;
#   - the Pub/Sub emulator is restarted empty for each lesson that uses it,
#     with its output in a file rather than in a second terminal;
#   - the captures take a lock, because there is one port 8085 on this machine;
#   - python3 is Ubuntu 24.04's own 3.12: PYTHON3_DIR names a directory holding
#     a `python3` link to python3.12, and it goes first on the path.
#
# Helpers:
#   lab                  enter the lab: HOME, PATH, env.sh, TZ, the lock
#   net                  give gcloud the recording machine's proxy (see above)
#   pubsub_fresh         the Pub/Sub emulator restarted empty on 8085
#   pubsub_stop
#   block NAME           a marker line the paste tool splits the output on
#   run CMD              print the prompt and CMD, run it, print what it printed
#   say TEXT             print a line into the block without running anything
#   at DIR               the directory the prompt shows (default ~/gcp)
#   fences LANG FILE N   the Nth ```LANG fence of FILE, counted from 1
#   sh_fences FILE N     the same for ```sh
#   example FILE NAME    the code parts of the schooling-example whose file is NAME

GCP_COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB_ROOT=${LAB_ROOT:-/opt/gcplab}
LAB_HOME=/home/ana
PROMPT_DIR='~/gcp'
mkdir -p "$LAB_ROOT"

clean_env() {
  local v
  for v in $(env | grep -oE '^(CLOUDSDK|GOOGLE)[A-Z0-9_]*'); do unset "$v"; done
  unset PUBSUB_EMULATOR_HOST TF_PLUGIN_CACHE_DIR CHECKPOINT_DISABLE JAVA_TOOL_OPTIONS
  export HOME=$LAB_HOME TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
  export PATH="${PYTHON3_DIR:+$PYTHON3_DIR:}/usr/bin:/bin"
}

lab() {
  exec 9>"$LAB_ROOT/capture.lock"
  flock 9
  clean_env
  [ -f "$HOME/gcp/env.sh" ] || { echo "no lab: run lesson 1's captures.sh first"; exit 1; }
  # shellcheck disable=SC1091
  . "$HOME/gcp/env.sh"
  cd "$HOME/gcp" || exit 1
}

net() {
  export CLOUDSDK_PROXY_TYPE=http CLOUDSDK_PROXY_ADDRESS=127.0.0.1 \
    CLOUDSDK_PROXY_PORT="${HTTPS_PROXY##*:}" CLOUDSDK_CORE_CUSTOM_CA_CERTS_FILE=/root/.ccr/ca-bundle.crt
}

pubsub_stop() {
  local pid
  pid=$(cat "$LAB_ROOT/pubsub.pid" 2>/dev/null) && kill -- "-$pid" 2>/dev/null
  rm -f "$LAB_ROOT/pubsub.pid"
  for _ in $(seq 40); do curl -s -o /dev/null http://localhost:8085/ || return 0; sleep 0.25; done
  echo "the emulator did not stop"; exit 1
}

pubsub_fresh() {
  pubsub_stop
  setsid bash -c 'echo $$ > "$0/pubsub.pid"; exec gcloud beta emulators pubsub start --host-port=localhost:8085' \
    "$LAB_ROOT" </dev/null >"$LAB_ROOT/pubsub.log" 2>&1 &
  for _ in $(seq 120); do
    curl -s -o /dev/null http://localhost:8085/ && break; sleep 0.25
  done
  curl -s -o /dev/null http://localhost:8085/ || { echo "the emulator did not start"; cat "$LAB_ROOT/pubsub.log"; exit 1; }
  trap pubsub_stop EXIT
}

block() { printf '##### %s\n' "$1"; }
at() { PROMPT_DIR=$1; }
say() { printf '%s\n' "$*"; }
run() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; bash -c "$*" 2>&1 || true; }

fences() { # LANG FILE N: the Nth fence labelled LANG in FILE, counted from 1
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
lang, path, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
found = re.findall(r'^```' + re.escape(lang) + r'\n(.*?)^```$', open(path).read(), re.S | re.M)
if not 1 <= n <= len(found):
    sys.exit(f'{path}: no {lang} fence number {n} (there are {len(found)})')
sys.stdout.write(found[n - 1])
PY
}
sh_fences() { fences sh "$1" "$2"; }

example() {
  python3 - "$1" "$2" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
blocks = re.findall(r'^```schooling-example\n(.*?)\n```$', text, re.S | re.M)
found = [b for b in (json.loads(x) for x in blocks) if b.get('file') == sys.argv[2]]
if len(found) != 1:
    sys.exit(f'{sys.argv[1]}: expected one example for {sys.argv[2]}, found {len(found)}')
sys.stdout.write(''.join(p['code'] for p in found[0]['parts']))
PY
}

# THE TERRAFORM DIRECTORIES. Lesson 2 has the student write provider.tf, and
# every later lesson that plans starts a directory of its own with a copy of
# it. tf_dir NAME empties ~/gcp/NAME, puts lesson 2's provider.tf in it, runs
# `terraform init` quietly (the prose shows the command; lesson 2 shows its
# output) and moves the prompt there. tf_file LESSONFILE N NAME writes the Nth
# ```hcl fence of a lesson's section into NAME.
L2_ESTATE=$GCP_COURSE/lessons/le-mj28pc0k/the-estate-as-code.md
tf_dir() {
  rm -rf "$HOME/gcp/$1" && mkdir -p "$HOME/gcp/$1" && cd "$HOME/gcp/$1" || exit 1
  fences hcl "$L2_ESTATE" 1 > provider.tf || exit 1
  at "~/gcp/$1"
  terraform init -input=false > "$LAB_ROOT/init.log" 2>&1 || { cat "$LAB_ROOT/init.log"; exit 1; }
}
tf_file() { fences hcl "$1" "$2" > "$3" || exit 1; }
