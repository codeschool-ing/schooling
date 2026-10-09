#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs lessons 1 to 16 show, read out of the
# lessons that show them whole (stage); and the week lesson 3 replays (lab.sh
# week), kept from that lesson's capture or replayed again if anything that
# decides it has changed. The replies in it are llama3.2:3b's (a80c4f17acd5)
# through Ollama 0.40.0, at temperature 0; the customers and their thumbs are
# the course's, as lesson 3 says.
#
# The alert rules are evaluated over the replayed week by alerts.py, as an
# alerting system would evaluate them each hour; no alerting system runs here
# and nobody was paged. The exposition is prometheus-client 0.26.0's own
# output; no Prometheus server scrapes it.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage traffic.py le-pdj3wk00/what-customers-type.md
stage replay.py le-3s3pd3qk/replaying-a-week.md
stage checks.py le-33kcjt4d/rules-for-the-form.md
stage replies.py le-9w1fwkcz/the-quality-panel.md
stage series.py le-9w1fwkcz/the-quality-panel.md
stage exposition.py le-9w1fwkcz/counters-and-labels.md
stage alerts.py le-9w1fwkcz/four-rules.md
quiet lab exec 'python traffic.py data/traffic.jsonl'
quiet lab week

block series
on 'python series.py'

block exposition
on 'python exposition.py'

block alerts
on 'python alerts.py'
