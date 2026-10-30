#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   LAB_HOSTS=1 bash lessons/le-r7arqrvr/captures.sh
#
# LAB_HOSTS=1 because the container's port is published by Docker on the
# machine's own network; nothing here reaches anything outside the laptop.
#
# What is STAGED rather than typed:
#   - app.py and the Dockerfile are read out of the blocks of the section
#     `a-container-that-fits`, and main.tf out of `scale-to-zero`;
#   - every container is removed at the start and at the end, so a run
#     leaves nothing behind (LAB_HOSTS runs take a lock, one at a time);
#   - `sleep 1` after each `docker run -d`, quiet, gives the server a moment
#     to start listening before the first curl;
#   - `terraform init`, whose output lesson 1 shows, runs quietly, with a
#     provider cache private to this run (TF_PLUGIN_CACHE_DIR).
#
# The timings are this laptop's: Docker 29.9.2 on Ubuntu 24.04. Nothing about
# them is a measurement of Cloud Run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

cleanup() { docker rm -f orders orders-sh orders-local orders-9090 >/dev/null 2>&1; }
cleanup
mkdir -p orders cloudrun
from_lesson "$HERE/a-container-that-fits.md" orders/app.py > orders/app.py
from_lesson "$HERE/a-container-that-fits.md" orders/Dockerfile > orders/Dockerfile
from_lesson "$HERE/scale-to-zero.md" cloudrun/main.tf > cloudrun/main.tf

block build
run 'docker build -q -t orders:1 orders'
run 'docker image ls orders:1 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"'

block run
run 'docker run -d --name orders -p 8080:8080 -e PORT=8080 orders:1'
quiet 'sleep 1'
run 'curl -s localhost:8080/orders; echo'
run 'curl -s localhost:8080/health; echo'
run 'curl -s -i localhost:8080/nothing; echo'

block port
run 'docker run -d --name orders-9090 -p 9090:9090 -e PORT=9090 orders:1'
quiet 'sleep 1'
run 'curl -s localhost:9090/health; echo'
run 'docker logs orders-9090'

block local-only
run 'docker run -d --name orders-local -p 8081:8081 orders:1 python3 -m http.server --bind 127.0.0.1 8081'
quiet 'sleep 1'
run 'curl -sS localhost:8081/; echo "exit status $?"'

block stop
run 'time docker stop orders'
run 'docker logs orders'

block stop-shell
run "docker run -d --name orders-sh -p 8080:8080 orders:1 sh -c 'python3 app.py'"
quiet 'sleep 1'
run 'time docker stop orders-sh'
run 'docker inspect orders-sh --format "{{.State.ExitCode}}"'

block plan
cd cloudrun || exit 1
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.tfcache; mkdir -p $TF_PLUGIN_CACHE_DIR'
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|^      \\+ (name|location|ingress) |image|min_instance|max_instance|cpu|memory|container_port|^Plan'"

block deploy
run 'gcloud run deploy orders --image=southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:1 --region=southamerica-east1'

cleanup
