# Sourced by the lessons' captures.sh. Not for the student, who has none of it.
#
# THE STUDENT'S LAB IS BUILT BY LESSON 1, OUT OF ITS OWN TEXT, and every other
# lesson is recorded in that lab: the home directory lesson 1's captures.sh
# filled, with the AWS CLI in ~/.local, moto in ~/aws/venv and ~/aws/env.sh.
#
# WHAT IS STAGED, and why, for every lesson (each captures.sh adds its own):
#   - the recording machine cannot give the lab a user of its own, so ana's home
#     is the directory LAB_HOME below, and HOME points at it. The prompt is
#     printed as ana@laptop:~/aws$, and no command quoted prints the real path;
#   - every AWS_* variable the recording machine's environment carried is unset
#     before ~/aws/env.sh is read, so nothing of the author's reaches the tools;
#   - moto is restarted empty for each lesson and given a fixed random seed
#     (POST /moto-api/seed?a=42), so the ids it invents are the same on every
#     run and the prose can quote them. A student's moto invents different ones;
#   - the captures take a lock, because there is one port 4567 on this machine;
#   - python3 is Ubuntu 24.04's own 3.12: PYTHON3_DIR names a directory holding
#     a `python3` link to python3.12, and it goes first on the path.
#
# Helpers:
#   lab                  enter the lab: HOME, PATH, env.sh, TZ, the lock
#   moto_fresh [VAR=V]   moto restarted empty on 4567, seeded; VARs go to the server
#   moto_stop
#   block NAME           a marker line the paste tool splits the output on
#   run CMD              print the prompt and CMD, run it, print what it printed
#   say TEXT             print a line into the block without running anything
#   at DIR               the directory the prompt shows (default ~/aws)
#   sh_fences FILE N     the Nth ```sh fence of FILE, counted from 1
#   example FILE NAME    the code parts of the schooling-example whose file is NAME

AWS_COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB_ROOT=${LAB_ROOT:-/opt/awslab}
LAB_HOME=$LAB_ROOT/home/ana
PROMPT_DIR='~/aws'

lab() {
  exec 9>"$LAB_ROOT/capture.lock"
  flock 9
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_REGION \
    AWS_DEFAULT_REGION AWS_CONFIG_FILE AWS_SHARED_CREDENTIALS_FILE AWS_ENDPOINT_URL AWS_CA_BUNDLE
  export HOME=$LAB_HOME TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
  [ -n "${PYTHON3_DIR:-}" ] && export PATH="$PYTHON3_DIR:$PATH"
  [ -f "$HOME/aws/env.sh" ] || { echo "no lab: run lesson 1's captures.sh first"; exit 1; }
  # shellcheck disable=SC1091
  . "$HOME/aws/env.sh"
  cd "$HOME/aws" || exit 1
}

moto_stop() {
  local pid
  pid=$(cat "$LAB_ROOT/moto.pid" 2>/dev/null) && kill "$pid" 2>/dev/null
  rm -f "$LAB_ROOT/moto.pid"
  for _ in $(seq 40); do curl -s -o /dev/null http://127.0.0.1:4567/moto-api/ || return 0; sleep 0.25; done
  echo "moto did not stop"; exit 1
}

moto_fresh() {
  moto_stop
  # /moto-api/ is moto's own control address and is never counted by
  # INITIAL_NO_AUTH_ACTION_COUNT, so waiting for it spends none of the count.
  setsid env "$@" bash -c 'echo $$ > "$0/moto.pid"; exec moto_server -p 4567' "$LAB_ROOT" \
    </dev/null >"$LAB_ROOT/moto.log" 2>&1 &
  for _ in $(seq 80); do
    curl -s -o /dev/null http://127.0.0.1:4567/moto-api/ && break; sleep 0.25
  done
  curl -s -o /dev/null -X POST 'http://127.0.0.1:4567/moto-api/seed?a=42' || { echo "moto did not start"; exit 1; }
  trap moto_stop EXIT
}

block() { printf '##### %s\n' "$1"; }
at() { PROMPT_DIR=$1; }
say() { printf '%s\n' "$*"; }
run() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; bash -c "$*" 2>&1 || true; }

sh_fences() {
  python3 - "$1" "$2" <<'PY'
import re, sys
fences = re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
n = int(sys.argv[2])
if not 1 <= n <= len(fences):
    sys.exit(f'{sys.argv[1]}: no sh fence number {n} (there are {len(fences)})')
sys.stdout.write(fences[n - 1])
PY
}

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
