#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of azure-compute (choosing the
# compute: request profile, cost model and effort to migrate), as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-5w6gq34a/captures.sh
#
# There is no Azure account and no price list. compare.py and rates.json are
# taken out of the examples in this lesson's section `the-cost-model`, so the
# program run is the one the student copies; every number it prints is
# arithmetic on rates.json, whose rates are ILLUSTRATIVE, NOT AZURE'S PRICES
# (the three Container Apps free grants in it are Microsoft's documented ones).
# The Retail Prices API request the lesson shows is NOT run: this machine is
# refused prices.azure.com.
#
# The `memory` block runs two copies of the shop's image in Docker, to show
# that orders kept in a process's memory are not shared between replicas.
#
# What is STAGED rather than typed:
#   - app.py and the Dockerfile are taken out of lesson 7's text, and the image
#     is built quietly FROM this machine's python:3.12-slim, which lab.sh
#     rebuilt with the proxy's certificate added; the student's base image has
#     none of it, and the build needs nothing from the network after the pull;
#   - the lab waits quietly for each container to answer /healthz before the
#     first request, and removes both containers and the image at the end.
#
# The container ids `docker run` prints differ on every run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
L7=$HERE/../le-gpjpyeh5

from_example "$HERE/the-cost-model.md" rates.json > rates.json
from_example "$HERE/the-cost-model.md" compare.py > compare.py

block compare
run 'python3 compare.py'

block zero
run "sed 's/^CA_MIN = 2 /CA_MIN = 0 /' compare.py > zero.py"
run 'python3 zero.py'

block shop
run 'python3 compare.py shop=2,2,2,2,2,2,2,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,2'

block shop-quiet
run 'python3 compare.py shop=0,0,0,0,0,0,0,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,0'

block shop-triple
run 'python3 compare.py shop3=6,6,6,6,6,6,6,30,60,90,120,120,90,60,60,90,120,180,240,240,180,120,60,6'

block memory
mkdir -p shop
from_example "$L7/the-shop-at-home.md" app.py > shop/app.py
from_lesson "$L7/the-shop-at-home.md" Dockerfile > shop/Dockerfile
quiet 'docker rm -f shop-a shop-b'
quiet 'docker build -t shop:1.0 shop'
run 'docker run -d --name shop-a -p 8081:8080 shop:1.0'
run 'docker run -d --name shop-b -p 8082:8080 shop:1.0'
quiet 'until curl -sf localhost:8081/healthz && curl -sf localhost:8082/healthz; do sleep 0.5; done'
run "curl -s -X POST localhost:8081/orders -d '{\"item\": \"coffee\", \"qty\": 2}'; echo"
run 'curl -s localhost:8081/orders; echo'
run 'curl -s localhost:8082/orders; echo'
run 'docker restart shop-a'
quiet 'until curl -sf localhost:8081/healthz; do sleep 0.5; done'
run 'curl -s localhost:8081/orders; echo'
quiet 'docker rm -f shop-a shop-b'
quiet 'docker rmi shop:1.0'
