#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-cwnhwgr0/captures.sh
#
# Nothing here talks to Google or to a container: it is arithmetic over the
# price sheet of lesson 1, run in a network namespace with only loopback.
#
# What is STAGED rather than typed:
#   - prices.py is read out of the example in lesson 1's `the-price-sheet`, and
#     compare.py out of the example in this lesson's `the-cost-model`, as the
#     student saves them.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py
from_example "$HERE/the-cost-model.md" compare.py > compare.py

block volumes
run 'python3 -c "print(30 * 3600 * 24, 30 * 3600 * 24 * 730 / 24)"'

block compare
run 'python3 prices.py | python3 compare.py'

block worked
run 'python3 prices.py | python3 compare.py orders=2,1,1,1,1,1,2,6,18,35,40,38,30,36,40,38,30,22,14,10,8,6,4,3'
run 'python3 prices.py | python3 compare.py orders-x10=20,10,10,10,10,10,20,60,180,350,400,380,300,360,400,380,300,220,140,100,80,60,40,30'
