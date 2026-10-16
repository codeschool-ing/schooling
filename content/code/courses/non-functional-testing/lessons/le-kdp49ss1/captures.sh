#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: lesson 1's boxoffice and this lesson's
# observed.py, prometheus.yml, promql.sh and traffic.js, copied out of the
# sections that show them; a fresh database from seed.py; Prometheus, already
# installed from Ubuntu's archive when the machine was built. The machine has
# no service manager, so the node exporter, which apt starts as a service on a
# student's VM, is started here by hand. The servers (observed.py, the node
# exporter, Prometheus) and the k6 run go in the background where the lesson
# has the student use separate terminals; `log` prints what those terminals
# showed. Timings, rates, ids and dates differ on every run; the prose quotes
# this one.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l22
shown "$L1/the-boxoffice.md" "$HERE_DIR/observed.md" "$HERE_DIR/prometheus.md" 2>/dev/null

block version
run 'prometheus --version | head -1; promtool --version | head -1'

at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 observed.py > requests.log'
block observed-start
echo 'ana@nft:~/boxoffice$ python3 observed.py > requests.log'
log
block observe
run 'curl -si localhost:8000/shows/990'
run 'curl -s -H "X-Request-Id: ana-test-1" -X POST localhost:8000/bookings -d '"'"'{"show_id": 990, "seat": 12, "customer": "ana"}'"'"
run 'curl -s localhost:8000/nope'
run 'cat requests.log'
block metrics
run "curl -s localhost:8000/metrics | grep -E 'TYPE|_total|route=\"/bookings\"'"

PORT=9100 serve 'prometheus-node-exporter' node
at '~/monitor'
PORT=9090 serve 'prometheus --config.file=prometheus.yml --storage.tsdb.path=data' prom
sleep 15
block prom-start
echo 'ana@nft:~/monitor$ prometheus --config.file=prometheus.yml --storage.tsdb.path=data'
log prom | grep -E 'Starting Prometheus|Server is ready'
block up
run "sh promql.sh up"

PORT=6565 serve 'k6 run traffic.js' k6
sleep 45
block queries
run "sh promql.sh 'sum by (route) (rate(boxoffice_requests_total[1m]))'"
run "sh promql.sh 'sum by (status) (rate(boxoffice_requests_total[1m]))'"
run "sh promql.sh 'sum(rate(boxoffice_requests_total{status=~\"5..\"}[1m])) / sum(rate(boxoffice_requests_total[1m]))'"
run "sh promql.sh '(sum(rate(boxoffice_requests_total{status=~\"5..\"}[1m])) or vector(0)) / sum(rate(boxoffice_requests_total[1m]))'"
run "sh promql.sh 'histogram_quantile(0.95, sum by (le, route) (rate(boxoffice_request_duration_seconds_bucket{route!=\"other\"}[1m])))'"
run "sh promql.sh '1 - avg(rate(node_cpu_seconds_total{mode=\"idle\"}[1m]))'"
sleep 20
block k6
echo 'ana@nft:~/monitor$ k6 run traffic.js'
echo '…'
log k6 | sed -n '/TOTAL RESULTS/,$p' | grep -v '^running\|^default'
block buckets
run "curl -s localhost:8000/metrics | grep 'shows/{id}'"
at '~/boxoffice'
block logs
run 'wc -l requests.log'
run "jq -s -c 'group_by(.status) | map({status: .[0].status, requests: length})' requests.log"
run "jq -c 'select(.request_id == \"ana-test-1\")' requests.log"
stop k6; stop prom; stop node; stop
