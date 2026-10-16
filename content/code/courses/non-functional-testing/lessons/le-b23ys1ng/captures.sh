#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: lesson 1's boxoffice; lesson 22's
# observed.py, promql.sh and traffic.js; this lesson's alerts.yml,
# alerts_test.yml, flaky.py and the new prometheus.yml (which replaces lesson
# 22's, because it is copied second); a fresh database from seed.py. The
# alertmanager.yml the lesson shows is copied too and never used: Alertmanager
# is not installed on this machine. The node exporter, which apt starts as a
# service on a student's VM, is started by hand. The servers and the k6 run go
# in the background where the lesson has the student use separate terminals,
# and `log` prints what Prometheus's terminal showed. The flaky payment
# provider is random, so the ratios, times and ids differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L22="$HERE_DIR/../le-kdp49ss1"

machine l24
shown "$L1/the-boxoffice.md" "$L22/observed.md" "$L22/prometheus.md" \
  "$HERE_DIR/rule.md" "$HERE_DIR/firing.md" 2>/dev/null

at '~/monitor'
block check
run 'promtool check rules alerts.yml'
block test
run 'promtool test rules alerts_test.yml'
block test-fails
run "sed -i 's/for: 2m/for: 5m/' alerts.yml"
run 'promtool test rules alerts_test.yml'
run "sed -i 's/for: 5m/for: 2m/' alerts.yml"

at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 flaky.py > requests.log'
PORT=9100 serve 'prometheus-node-exporter' node
at '~/monitor'
PORT=9090 serve 'prometheus --config.file=prometheus.yml --storage.tsdb.path=data' prom
PORT=6565 serve 'k6 run --duration 4m traffic.js' k6
sleep 50
block pending
run "curl -s localhost:9090/api/v1/alerts | jq -c '.data.alerts[] | {alert: .labels.alertname, state, activeAt, value}'"
sleep 100
block firing
run "curl -s localhost:9090/api/v1/alerts | jq '.data.alerts[]'"
block by-route
run "sh promql.sh 'sum by (route) (rate(boxoffice_requests_total{status=~\"5..\"}[5m])) / sum by (route) (rate(boxoffice_requests_total[5m]))'"
run "sh promql.sh 'sum(rate(boxoffice_requests_total{route=\"/bookings\"}[5m])) / sum(rate(boxoffice_requests_total[5m]))'"
block errors
at '~/boxoffice'
run "jq -c 'select(.level == \"error\")' requests.log | head -2"
block notifier
echo 'ana@nft:~/monitor$ prometheus --config.file=prometheus.yml --storage.tsdb.path=data'
echo '…'
log prom | grep -m 2 'notifier'
stop k6; stop prom; stop node; stop
