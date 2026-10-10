#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of qa-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. tickets.py and orders.py are read out
# of the lessons by lab/extract.py, so the programs run are the programs
# printed. Every block runs in one container, in order, because the database
# file aurora.db keeps what the earlier blocks wrote: that is the point of the
# lesson. It starts empty.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-bsh7htsd <<'S'
rm -f aurora.db
block place
on 'python orders.py thu 20:00 35 35 8'
on 'python orders.py sat 15:00 35 35'

block look
on 'python -m sqlite3 aurora.db "SELECT * FROM orders"'

block refuse
on 'python orders.py sat 15:00 35 35 35 35 35 35 35'
on 'python orders.py sat 15:00'

block after
on 'python -m sqlite3 aurora.db "SELECT * FROM orders"'

block report
on 'python -m sqlite3 aurora.db "SELECT session, sum(tickets) FROM orders GROUP BY session"'

block inherit
on 'python orders.py wed 20:00 35 8'
S
