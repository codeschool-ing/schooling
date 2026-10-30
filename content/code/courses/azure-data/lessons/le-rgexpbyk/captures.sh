#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with Azurite started and empty. count.py and costs.py are read
# out of the examples in counting-requests.md and small-blobs.md, so there is
# no second copy here.
#
# STAGED: Azurite is started by `services` rather than by the
# `docker compose up -d` the student types. Nothing else: costs.py needs no
# emulator, and every price in it is illustrative and says so.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1

example "$HERE/counting-requests.md" count.py ~/azure/count.py || exit 1
block count
run 'python count.py'

example "$HERE/small-blobs.md" costs.py ~/azure/costs.py || exit 1
block costs
run 'python costs.py'
block end
