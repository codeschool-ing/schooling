#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of aws-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-9c6svqzr/captures.sh
#   LAB_HOSTS=1 bash lessons/le-9c6svqzr/captures.sh hosts
#
# orders.py, lambda_app.py, server.py and egress.py are read out of the
# lesson's own fences (from_lesson), so the files run are the files shown.
#
# The default part runs server.py on the laptop and asks it for two quotes;
# nothing in it talks to moto or to AWS.
#
# `hosts` needs the machine's own network and Docker: it runs lambda_app.py in
# AWS's Lambda base image with the Runtime Interface Emulator inside, as lesson
# 14 does, and runs egress.py over the EC2 price file that prices.py caches
# (read out of lesson 1's example, at its pinned version; prices.py downloads
# the file through the recording machine's proxy only when the cache lacks it).
#
# What is STAGED rather than typed:
#   - the files are written by the script, from the lesson;
#   - a pause of one second after starting server.py, and of two after each
#     `docker run -d`, where the student is simply slower than a script;
#   - the base image was on this machine before the run, pulled through a
#     mirror and tagged with the name lesson 14 uses;
#   - after `docker stop`, a wait until Docker has removed the container.
#
# Request ids, container ids and timings differ on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
SEAMS=$HERE/portable-seams.md

mkdir -p shop
for f in orders.py lambda_app.py server.py; do from_lesson "$SEAMS" "$f" > "shop/$f"; done
cd shop || exit 1

if [ "${1:-}" = hosts ]; then
  INVOKE='curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations'
  block lambda
  run 'docker run --rm -d --name shop -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 lambda_app.handler > /dev/null'
  quiet 'sleep 2'
  run "$INVOKE -d '{\"body\": \"{\\\"items\\\": {\\\"tee\\\": 2, \\\"mug\\\": 1}}\"}'; echo"
  run "$INVOKE -d '{\"body\": \"{\\\"items\\\": {\\\"hat\\\": 1}}\"}'; echo"
  run 'docker stop shop'
  quiet 'while docker inspect shop >/dev/null 2>&1; do sleep 0.2; done'
  cd .. || exit 1
  export HTTPS_PROXY=$LAB_PROXY
  from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py
  quiet 'python3 prices.py ec2'
  from_lesson "$HERE/what-leaving-costs.md" egress.py > egress.py
  block egress
  run 'python3 egress.py'
  exit 0
fi

block server
run 'python3 server.py 2> server.log &'
quiet 'sleep 1'
run "curl -s -XPOST localhost:8008/quote -d '{\"items\": {\"tee\": 2, \"mug\": 1}}'; echo"
run "curl -s -XPOST localhost:8008/quote -d '{\"items\": {\"hat\": 1}}'; echo"
run 'kill %1'

block count
run 'wc -l orders.py lambda_app.py server.py'
run 'grep -n "quote" lambda_app.py server.py'
