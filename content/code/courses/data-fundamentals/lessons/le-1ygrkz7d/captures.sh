#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt
#   python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. Every program run here is read out of
# this lesson's sections by lab/extract.py and lands in ~/roda/sources, which
# section `databases` tells the student to create; so the program run is the
# program printed.
#
# STAGED rather than typed: `export RODA_TOKEN=...` and `python api.py &`, which
# section `apis` gives as an `sh` fence, are run here by the script rather than
# through `on`, because each `on` is a shell of its own and the server must
# outlive it. The script starts the server with the .venv's python by its path,
# which is the python the student has active, and discards its output, as its
# `log_message` already does. The writer that dies in `half` is export.py given
# a byte count, which is how the section stages it. The broken log line in
# `log` is pasted into parse_log.py, as the section says.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-1ygrkz7d <<'S'
cd sources

block incremental
on 'python app.py'
on 'python incremental.py'
on 'python later.py'
on 'python incremental.py'

block cdc
on 'python app.py'
on 'python triggers.py'
on 'python later.py'
on 'python changes.py'

export RODA_TOKEN=lab-token-not-a-secret
~/roda/.venv/bin/python api.py >/dev/null 2>&1 &
sleep 1
block walk
on 'python walk.py'

block token
on 'RODA_TOKEN=wrong python walk.py 2>&1 | tail -1'
kill %1

block half
on 'python export.py 15000'
on 'python load.py'
on 'python load.py --careful'

block whole
on 'python export.py'
on 'python load.py --careful'
on 'ls drop/2025-09-15'

block log
on 'python parse_log.py'

block docks
on 'python docks.py'
S
