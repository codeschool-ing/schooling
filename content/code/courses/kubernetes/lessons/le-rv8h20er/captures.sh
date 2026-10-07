#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# This lesson runs no cluster. It is the shop on Docker Compose, on one
# machine, which is what the course starts from. Container ids and the uptime
# Docker prints differ on every run.
#
# What is STAGED rather than typed: removing whatever an earlier run left
# (`docker compose down`), and the pauses between commands, which give the
# restart policy time to act.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"
quiet 'docker compose down --remove-orphans'

block one-host
put compose.yaml <<'CODE'
services:
  web:
    image: shop:1.0
    ports:
      - "8080:8080"
    restart: always
CODE
run 'docker compose up -d'
quiet 'sleep 2'
run 'curl -s localhost:8080'
run 'docker compose ps --format "table {{.Name}}\t{{.Image}}\t{{.Status}}"'
run 'sudo kill -9 $(docker inspect -f "{{.State.Pid}}" shop-web-1)'
quiet 'sleep 3'
run 'docker inspect -f "{{.RestartCount}} restart(s), running: {{.State.Running}}" shop-web-1'
run 'docker compose up -d --scale web=3'
quiet 'docker compose up -d --scale web=1'

block the-update
put probe.sh <<'CODE'
#!/bin/sh
# Ask the shop 300 times, 20 ms apart, and print each answer's status code.
# 000 means curl got no answer at all.
for i in $(seq 300); do
  curl -s -o /dev/null -m 1 -w '%{http_code}\n' localhost:8080
  sleep 0.02
done
CODE
quiet 'chmod +x probe.sh'
run 'sed -i "s/shop:1.0/shop:1.1/" compose.yaml'
run './probe.sh > codes.txt & docker compose up -d; wait'
run 'sort codes.txt | uniq -c'
run 'curl -s localhost:8080'
quiet 'docker compose down'
