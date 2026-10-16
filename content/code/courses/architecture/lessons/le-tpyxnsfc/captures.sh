#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# The shop's three files are EXTRACTED from the section "Quitanda, as one
# program" (the-shop.md) exactly as the copy button hands them over, and saved
# into ~/lab/monolith, the directory the lesson tells the student to make.
# alpine:3.22 is removed first, so "checks" shows the pull a fresh machine makes.
# Staged: the images are built once beforehand (lab.sh, "prebuild"), so the
# `up --build` below finds its layers cached. Recorded on Ubuntu 24.04,
# TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-tpyxnsfc
lab reset
quiet 'docker image rm -f alpine:3.22'

block checks
run 'docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"'
run 'docker compose version'
run 'docker run --rm alpine:3.22 echo hello from a container'

at '~/lab/monolith'
for f in app.py Dockerfile compose.yaml; do save $L/the-shop.md $f '~/lab/monolith/'$f; done
prebuild
block up
run 'ls'
run 'docker compose up -d --build --quiet-build'
run 'docker compose ps'
sleep 2
block products
run 'curl -s localhost:8000/products'
block order
run "curl -s -X POST localhost:8000/orders -d '{\"sku\": \"coffee\", \"qty\": 2, \"card\": \"4111111111111111\"}'"
block logs
run 'docker compose logs shop'
block declined
run "curl -s -i -X POST localhost:8000/orders -d '{\"sku\": \"coffee\", \"qty\": 1, \"card\": \"4000000000000002\"}'"
run 'curl -s localhost:8000/products | grep coffee'
run 'curl -s localhost:8000/orders'
block too-many
run "curl -s -i -X POST localhost:8000/orders -d '{\"sku\": \"coffee\", \"qty\": 50, \"card\": \"4111111111111111\"}'"
run 'curl -s localhost:8000/orders'
block port
run 'docker compose -p second up -d --quiet-build'
quiet 'docker compose -p second down'
block oom
run 'docker run --name hog --memory 64m python:3.12-slim python -c "b = bytearray(200 * 1024 * 1024)"; echo "exit code $?"'
run 'docker inspect --format "{{.State.OOMKilled}} {{.State.ExitCode}}" hog'
quiet 'docker rm hog'
quiet 'docker compose down -v'
