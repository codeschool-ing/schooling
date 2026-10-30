#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: charges.py, modes.py and flood.py are the
# fences those names introduce in request-units.md, three-ways-to-pay.md and
# throttling.md; sizing.py and writer.py are the schooling-examples of
# sizing.md and retries.md. Nothing is copied here.
#
# STAGED: the Cosmos DB emulator is started empty by `services`, where the
# student types `docker compose --profile cosmos up -d`. The timing flood.py
# prints is this machine's against the emulator, and changes between runs.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services cosmos || exit 1

file_fence "$HERE/request-units.md" charges.py > charges.py
file_fence "$HERE/three-ways-to-pay.md" modes.py > modes.py
example "$HERE/sizing.md" sizing.py sizing.py
file_fence "$HERE/throttling.md" flood.py > flood.py
example "$HERE/retries.md" writer.py writer.py

block charges
run 'python charges.py'
block modes
run 'python modes.py'
block sizing
run 'python sizing.py'
block flood
run 'python flood.py'
block defaults
run "python -c 'from azure.cosmos.documents import RetryOptions; r = RetryOptions(); print(r.MaxRetryAttemptCount, r.MaxWaitTimeInSeconds, r.FixedRetryIntervalInMilliseconds)'"
block writer
run 'python writer.py'
