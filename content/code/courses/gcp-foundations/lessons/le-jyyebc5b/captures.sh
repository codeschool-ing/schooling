#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# IT BUILDS THE STUDENT'S LAB FROM THE LESSON ITSELF, into an empty home. The
# section "setting-up" is read out of its ```sh fences and run as it stands:
# fence 2 downloads the Google Cloud CLI, fence 3 installs two components,
# fence 4 Terraform, fence 5 the virtual environment, fence 6 writes
# ~/gcp/env.sh, fence 7 sets the lab's properties, fence 8 is the line typed
# into every terminal and fence 9 starts the emulator. The first fence,
# apt-get, needs sudo and is not run: the script checks that its packages are
# installed and stops if one is missing. cost.py is read out of the example in
# "crossing-costs". The lab this leaves behind is the one every other lesson's
# capture runs in.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the emulator runs in the background with its output in a file, rather
#     than in a second terminal; the block `emulator-terminal` prints that file
#     under the command that started it, which is what the first terminal shows;
#   - the emulator's log grows by a dozen lines for every request; the block
#     `emulator-terminal` stops after the first request's last header;
#   - the block `failure-port` keeps the two lines of the Java stack trace that
#     name the failure, out of some forty, and the prose shows that grep;
#   - the block `failure-java` runs the emulator with a PATH that holds every
#     program the CLI needs except `java`, which is what a machine without the
#     Java runtime has. Nothing else about that run differs.
#
# THREE BLOCKS REACH GOOGLE ITSELF, on purpose and with the placeholder token:
# `failure-google` sends a Pub/Sub request to the real API, `region-set` lets
# gcloud try to check a region, and `regions` asks the real Compute Engine API
# for its regions and zones. All are refused, and the refusals are quoted as
# Google sent them. The downloads in fences 2 to 5
# reach dl.google.com, releases.hashicorp.com and PyPI.
#
# NOT PRODUCED HERE, and said so in the prose: the missing python3-venv (the
# machine has the package and the failure needs it absent), the apt lock, and
# everything in "a-real-account", which needs a Google account.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
SETUP="$HERE/setting-up.md"
SCRATCH=$(mktemp -d)

exec 9>"$LAB_ROOT/capture.lock"
flock 9
clean_env
pubsub_stop
rm -rf "$LAB_HOME" && mkdir -p "$LAB_HOME"
cd "$HOME" || exit 1

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }
for p in python3 python3.12-venv curl jq unzip openjdk-21-jre-headless; do
  installed "$p" || { echo "install first, as in the first fence: $p"; exit 1; }
done

fence() {
  sh_fences "$SETUP" "$1" > "$SCRATCH/fence-$1.sh" || exit 1
  bash -e "$SCRATCH/fence-$1.sh" > "$SCRATCH/fence-$1.log" 2>&1 \
    || { echo "fence $1 of setting-up.md failed:"; cat "$SCRATCH/fence-$1.log"; exit 1; }
}

# ---- the lab, built by the section's own commands ---------------------------
fence 2          # the Google Cloud CLI
(net; fence 3)   # two components, downloaded by gcloud itself
fence 4          # Terraform
fence 5          # the virtual environment
fence 6          # env.sh
(net; fence 7)   # the lab's properties; the region is checked against Google
cd ~/gcp || exit 1

block failure-path
# a new terminal, which opens in the home directory and has not read env.sh
cd ~ && at '~'
run 'gcloud version'
cd ~/gcp && at '~/gcp'

block failure-noenv
# the same new terminal, with gcloud found by its full path but env.sh unread
run '~/.local/google-cloud-sdk/bin/gcloud pubsub topics list'

# shellcheck disable=SC1090
. <(sh_fences "$SETUP" 8)
cd ~/gcp || exit 1

block failure-noserver
run 'gcloud pubsub topics list'

# failure-java is recorded here and printed after emulator-terminal, because
# both blocks start with the same line and the paste tool hands them out in the
# order the prose shows them
mkdir -p "$SCRATCH/nojava"
for c in bash sh dirname basename readlink uname cat env sed grep tr head ls mkdir rm python3; do
  ln -s "$(command -v "$c")" "$SCRATCH/nojava/$c" 2>/dev/null
done
PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$SCRATCH/nojava" \
  run 'gcloud beta emulators pubsub start --host-port=localhost:8085' > "$SCRATCH/failure-java.txt"

# fence 9, in the background: what the first terminal would show goes to a file
[ "$(sh_fences "$SETUP" 9)" = 'gcloud beta emulators pubsub start --host-port=localhost:8085' ] \
  || { echo "fence 9 changed"; exit 1; }
setsid bash -c 'echo $$ > "$0/pubsub.pid"; exec gcloud beta emulators pubsub start --host-port=localhost:8085' \
  "$LAB_ROOT" </dev/null >"$SCRATCH/pubsub.log" 2>&1 &
for _ in $(seq 120); do curl -s -o /dev/null http://localhost:8085/ && break; sleep 0.25; done
trap 'pubsub_stop; rm -rf "$SCRATCH"' EXIT

block check
run 'gcloud version'
run 'gcloud config list'
run 'gcloud pubsub topics create orders'
run 'gcloud pubsub topics list'
run 'terraform version'
run "python3 -c 'from importlib.metadata import version as v; print(v(\"duckdb\"), v(\"google-cloud-pubsub\"))'"
run 'cd ~ && du -sh .local/google-cloud-sdk .local/bin/terraform gcp/venv'
run 'ps -C java -o rss=,comm='

block emulator-terminal
printf 'ana@laptop:~/gcp$ gcloud beta emulators pubsub start --host-port=localhost:8085\n'
# the banner, and the lines the first request added, up to its last header
sed '/Forwarding key: authorization/q' "$SCRATCH/pubsub.log"

block failure-java
cat "$SCRATCH/failure-java.txt"

block failure-port
run 'timeout 20 gcloud beta emulators pubsub start --host-port=localhost:8085 2>&1 | grep -m2 -E "Exception|already in use"'
# timeout stops gcloud and not the Java process it started; that one is
# stopped here by pid, leaving the emulator of fence 9 alone
for p in $(pgrep -f 'cloud-pubsub-emulator'); do
  [ "$(ps -o pgid= -p "$p" | tr -d ' ')" = "$(cat "$LAB_ROOT/pubsub.pid")" ] || kill "$p" 2>/dev/null
done

block failure-google
net
run 'gcloud config unset api_endpoint_overrides/pubsub'
run 'gcloud pubsub topics list'
run 'gcloud config set api_endpoint_overrides/pubsub http://localhost:8085/'

block region-set
run 'gcloud config set compute/region southamerica-east1'

block regions
run 'gcloud compute regions list'
run 'curl -sS https://compute.googleapis.com/compute/v1/projects/planner-dev/zones'

# ---- what crossing a boundary costs ------------------------------------------
example "$HERE/crossing-costs.md" cost.py > ~/gcp/cost.py || exit 1
block cost
run 'python3 cost.py 500 zone'
run 'python3 cost.py 500 region'
run 'python3 cost.py 500 continent'
run 'python3 cost.py 500 us-region'
