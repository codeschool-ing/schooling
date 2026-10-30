#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with the Cosmos DB emulator started and empty. model.py,
# rekey.py and hier.py are read out of the fences that show them, and
# reads.py and spread.py out of the examples, so there is no second copy here.
#
# STAGED: the emulator is started by `services` rather than by the
# `docker compose --profile cosmos up -d` the student types, and the wait
# until it answers is not shown. spread.py needs no emulator.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services cosmos || exit 1

file_fence "$HERE/the-model.md" model.py > model.py
example "$HERE/three-reads.md" reads.py ~/azure/reads.py || exit 1
example "$HERE/choosing-the-key.md" spread.py ~/azure/spread.py || exit 1
file_fence "$HERE/choosing-the-key.md" rekey.py > rekey.py
file_fence "$HERE/hierarchical-keys.md" hier.py > hier.py

block model
run 'python model.py'
block reads
run 'python reads.py'
block spread
run 'python spread.py'
block rekey
run 'python rekey.py'
block hier
run 'python hier.py'
block end
