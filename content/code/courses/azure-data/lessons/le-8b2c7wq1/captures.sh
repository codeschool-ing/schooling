#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: feed.py, softdelete.py, order.py and
# versions.py are the fences those names introduce in the-feed.md,
# latest-version.md, processor.md and all-versions.md; processor.py is the
# schooling-example of processor.md. Nothing is copied here.
#
# STAGED: the Cosmos DB emulator and Azurite are started empty by `services`,
# where the student types `docker compose --profile cosmos up -d`. The runs
# follow one another in the order the sections give them, on the same data.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services cosmos || exit 1

file_fence "$HERE/the-feed.md" feed.py > feed.py
file_fence "$HERE/latest-version.md" softdelete.py > softdelete.py
file_fence "$HERE/processor.md" order.py > order.py
example "$HERE/processor.md" processor.py processor.py
file_fence "$HERE/all-versions.md" versions.py > versions.py

block feed
run 'python feed.py'
block soft
run 'python softdelete.py'
block proc
run 'python processor.py'
run 'python processor.py'
run 'python order.py o-5 c-8 990 && CRASH=before-checkpoint python processor.py'
run 'python processor.py'
block av
run 'python versions.py'
