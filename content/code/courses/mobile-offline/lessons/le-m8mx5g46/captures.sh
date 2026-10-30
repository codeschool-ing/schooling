#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner, and starts from no
# ~/planner/threads. Every program is taken from the lesson by lab/extract.py.
#
# STAGED: nothing beyond what lab.sh says for every lesson. blocking.ts and
# off-main.ts print whether a frame was drawn while the query ran, never a
# count or a time, so the lines repeat on any computer; paging.ts makes its
# rows from lesson 3's fixed seed.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/threads
LAB as 'rm -rf ~/planner/threads ~/planner/threads-try && mkdir -p ~/planner/threads'
put blocking.md slow.ts $P/slow.ts
put blocking.md blocking.ts $P/blocking.ts
put off-the-main-thread.md query-worker.ts $P/query-worker.ts
put off-the-main-thread.md off-main.ts $P/off-main.ts
put paging.md paging.ts $P/paging.ts

block blocking
run $P 'node blocking.ts'
block offmain
run $P 'node off-main.ts'
block paging
run $P 'node paging.ts'
