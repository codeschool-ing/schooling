#!/usr/bin/env bash
# The terminal session quoted in lesson 27 of gcp-data (choosing the store), as
# a script that produces it. The transcript in the lesson was copied from its
# output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S. This lesson asks no emulator anything: its one
# transcript is my_orders.py, read out of the example in one-workload.md so the
# program shown and the program run are the same file.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1

example "$LESSONS/le-s1jn5dd7/one-workload.md" my_orders.py my_orders.py || exit 1
block my-orders
run 'python3 my_orders.py'
