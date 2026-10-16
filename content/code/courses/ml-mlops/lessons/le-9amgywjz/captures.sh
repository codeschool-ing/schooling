#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh > out.txt   # needs the lab lesson 1 builds
#
# It puts ~/ml back to the shop as lesson 1 leaves it, stages the programs of
# lessons 1, 4 and 5 this lesson imports, then saves each program this lesson
# shows (read out of the lesson, stage below) and runs it. Timings in
# asking-for-one change on every run; the prose quotes their order of
# magnitude, not the digits.
#
# A line that starts with ana@dev:~/ml$ is what ana typed and what it printed.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9

quiet lab project
stage features.py le-xpaf8cg8/supervised.md
stage model.py le-fcd08ha8/the-trap.md
stage project.py le-d2vqq7mj/from-scripts-to-steps.md
stage featurestore.py le-9amgywjz/the-store.md

block filling-it
on 'python featurestore.py backfill 2025-06-01 2026-02-22'
on 'python featurestore.py snapshot 2026-02-28'
on 'ls -lh features.db'

stage asof.py le-9amgywjz/as-of-a-moment.md
block as-of-a-moment
on 'python asof.py'

block the-online-store
on 'python featurestore.py online'
on 'python featurestore.py get 2'
on 'python featurestore.py get 8'

stage lookup.py le-9amgywjz/asking-for-one.md
block asking-for-one
on 'python lookup.py'

stage reproduce.py le-9amgywjz/reproducible.md
block reproducible
on 'python reproduce.py'
