#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of mobile-offline, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine (which installed the sqlite3 shell, the apt line
# lesson 3 shows) and lesson 1's ~/planner, and starts from no ~/planner/db.
# Every program is taken from the lesson by lab/extract.py.
#
# STAGED: nothing beyond what lab.sh says for every lesson. big.ts makes its
# 20,000 sessions from a fixed seed, so the counts repeat.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner/db
LAB as 'rm -rf ~/planner/db ~/planner/db-try && mkdir -p ~/planner/db'
put sqlite-on-your-computer.md load.ts $P/load.ts
put sqlite-on-your-computer.md week.ts $P/week.ts
put queries-and-indexes.md big.ts $P/big.ts
put queries-and-indexes.md plan.ts $P/plan.ts
put transactions.md batch.ts $P/batch.ts
put transactions.md wal.ts $P/wal.ts

block load
run $P 'node load.ts'
block shell
run $P 'sqlite3 planner.db .tables'
run $P 'sqlite3 -header -column planner.db "SELECT * FROM sessions"'
block week
run $P 'node week.ts 2026-10-19'
block big
run $P 'node big.ts'
block plans
run $P 'node plan.ts'
run $P 'sqlite3 big.db "CREATE INDEX sessions_course_date ON sessions (course, date)"'
run $P 'node plan.ts'
run $P 'sqlite3 big.db "CREATE INDEX sessions_date ON sessions (date)"'
run $P 'node plan.ts'
block sizes
run $P 'rm big.db'
run $P 'node big.ts'
run $P 'wc -c big.db'
run $P 'sqlite3 big.db "CREATE INDEX sessions_course_date ON sessions (course, date)"'
run $P 'sqlite3 big.db "CREATE INDEX sessions_date ON sessions (date)"'
run $P 'wc -c big.db'
block batch
run $P 'node batch.ts'
block wal
run $P 'node wal.ts'
