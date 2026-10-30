#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner, and starts from no
# ~/planner/migrate. Every program is taken from the lesson by lab/extract.py.
#
# STAGED: nothing beyond what lab.sh says for every lesson. The databases are
# held in memory, and "launch 1" and "launch 2" in broken.ts are two runs of
# step 5 against the same connection, which is what two launches would do to
# the same file.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/migrate
LAB as 'rm -rf ~/planner/migrate ~/planner/migrate-try && mkdir -p ~/planner/migrate'
put user-version.md migrations.ts $P/migrations.ts
put every-path.md paths.ts $P/paths.ts
put every-path.md naive.ts $P/naive.ts
put the-migration-that-fails.md broken.ts $P/broken.ts

block paths
run $P 'node paths.ts'
block naive
run $P 'node naive.ts'
block broken
run $P 'node broken.ts'
