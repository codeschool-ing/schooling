#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with no emulator running. count.py and reads.py are read out of
# the examples in small-objects.md, so neither has a second copy here.
#
# STAGED: the student restarts fake-gcs-server in its own terminal with the
# first ```sh fence of small-objects.md, which tees every request it logs into
# ~/gcp/requests.log. Here that command is started in the background, read out
# of the fence, and stopped at the end like the other emulators.
#
# Nothing in this lesson is billed or metered: fake-gcs-server counts nothing.
# The prices are cloud.google.com/storage/pricing, /vpc/network-pricing and
# /cdn/pricing, read 2026-10-30, multiplied by counts in the open.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1

gcs_logged() {
  local cmd; cmd=$(fence "$HERE/small-objects.md" 1 | grep '^fake-gcs-server')
  ( cd "$HOME/gcp" && setsid bash -c "echo \$\$ > \"\$HOME/.emu-gcs.pid\"; exec bash -c '$cmd'" \
      > /dev/null 2>&1 < /dev/null & )
  for _ in $(seq 240); do
    (exec 3<>/dev/tcp/127.0.0.1/4443) 2>/dev/null && { sleep 0.5; return 0; }
    sleep 0.25
  done
  echo "fake-gcs-server did not start"; return 1
}

block meters
run "python3 -c 'print(round(0.035 / (0.0004 / 1000)), round(0.035 / (0.005 / 1000)))'"
run "python3 -c 'n = 1024 * 1024 // 4; print(n, round(n * 0.0004 / 1000, 4), round(n * 0.005 / 1000, 4))'"

example "$HERE/small-objects.md" count.py ~/gcp/count.py || exit 1
example "$HERE/small-objects.md" reads.py ~/gcp/reads.py || exit 1
gcs_logged || exit 1
B=quitanda-raw-prod
block count-taps
run "gcloud storage buckets create gs://$B --location=southamerica-east1"
run 'mkdir -p taps && for i in $(seq -w 1 20); do printf "{\"tap\":%d,\"screen\":\"cart\"}\n" $((10#$i)) > taps/tap-$i.json; done && ls taps | head -3'
run ': > requests.log'
run "gcloud storage cp --no-user-output-enabled taps/*.json gs://$B/raw/taps/dt=2026-10-01/"
run 'python3 count.py requests.log'
block count-packed
run ": > requests.log && cat taps/*.json > taps.jsonl && gcloud storage cp --no-user-output-enabled taps.jsonl gs://$B/raw/taps-packed/dt=2026-10-01/"
run 'python3 count.py requests.log'
block count-read
run ": > requests.log && gcloud storage cat 'gs://$B/raw/taps/dt=2026-10-01/*.json' | wc -l"
run 'python3 count.py requests.log'
run ": > requests.log && gcloud storage cat gs://$B/raw/taps-packed/dt=2026-10-01/taps.jsonl | wc -l"
run 'python3 count.py requests.log'
block count-list
run ": > requests.log && gcloud storage ls gs://$B/raw/taps/dt=2026-10-01/ | wc -l"
run 'python3 count.py requests.log'

block coldline
run "python3 -c 'print(2_000_000 * 0.02 / 1000, round(7.63 * (0.035 - 0.007), 4))'"

block reads
run 'python3 reads.py'

block inside
run "python3 -c 'print(round(5 * 1024 * 0.14, 2), round(2 * 1024 * 0.045, 2), round(500 * 0.01, 2))'"

C=quitanda-curated-prod
block requester-pays
run "gcloud storage buckets create gs://$C --location=southamerica-east1"
run "printf 'order_id,customer_id,total_cents\nord-01-1,c-17,4590\n' > history.csv && gcloud storage cp --no-user-output-enabled history.csv gs://$C/shared/history.csv"
run "gcloud storage buckets update gs://$C --requester-pays --log-http 2>&1 | grep -A1 '^== body start'"
run "gcloud storage buckets describe gs://$C --format=json | grep -c -i requester"
run "gcloud storage cat gs://$C/shared/history.csv"
block requester-header
run "gcloud storage cat --billing-project=planner-dev gs://$C/shared/history.csv --log-http 2>&1 | grep -c -i 'x-goog-user-project'"
run ': > requests.log'
run "python3 -c 'from google.cloud import storage; b = storage.Client().bucket(\"$C\", user_project=\"planner-dev\"); print(b.blob(\"shared/history.csv\").download_as_text(), end=\"\")'"
run "grep -o 'GET /download[^ ]*' requests.log"
