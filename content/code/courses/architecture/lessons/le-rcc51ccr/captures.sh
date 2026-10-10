#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# handler.py is EXTRACTED from the section "Serverless functions"
# (serverless.md) and runner.py from "Cold starts, measured" (cold-starts.md),
# as the copy button hands them over, into ~/lab/faas. Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-rcc51ccr
lab reset
at '~/lab/faas'
save $L/serverless.md handler.py '~/lab/faas/handler.py'
save $L/cold-starts.md runner.py '~/lab/faas/runner.py'
block cold
run "time docker run --rm -v ./:/fn -w /fn python:3.12-slim python runner.py once '{\"weight_g\": 7400}'"
block warm
run 'docker run -d --name warm -v ./:/fn -w /fn -p 127.0.0.1:8080:8080 python:3.12-slim python runner.py serve'
sleep 1
for i in 1 2 3; do
  run "curl -s -w '%{time_total}s\n' -d '{\"weight_g\": 7400}' localhost:8080"
done
block warm-stop
run 'docker rm -f warm'
