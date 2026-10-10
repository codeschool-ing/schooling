#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt
#   python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds: Ubuntu 24.04, ~/roda with its .venv,
# and the lines lesson 1 adds to ~/.bashrc. The programs app.py, ingest.py,
# transform.py, report.py, ingest_replace.py and trace.py are read out of this
# lesson's sections by lab/extract.py into ~/roda/lifecycle, so the program run
# is the program printed. The student makes that directory with the `mkdir`
# line in section `a-pipeline-you-can-read`; here the extraction has made it.
#
# ONE SESSION, IN SECTION ORDER, because each block depends on the state the
# one before it left: `twice` runs the appending ingest a second time over the
# raw zone `ingest` wrote, `replace` repairs it, and `trace` reads the repaired
# zones. Nothing else is staged.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-4rzasr7y <<'S'
cd lifecycle

block app
on 'python app.py'

block ingest
on 'python ingest.py 2025-09-15'

block raw
on 'find raw -type f | sort'
on 'head -1 raw/date=2025-09-15/rides.jsonl'

block transform
on 'python transform.py 2025-09-15'

block report
on 'python report.py 2025-09-15'

block zones
on 'find raw clean curated -type f | sort'
on 'head -4 curated/date=2025-09-15/rides_per_station.csv'

block twice
on 'python ingest.py 2025-09-15'
on 'wc -l raw/date=2025-09-15/*.jsonl'
on 'python transform.py 2025-09-15'
on 'python report.py 2025-09-15'

block replace
on 'python ingest_replace.py 2025-09-15'
on 'python ingest_replace.py 2025-09-15'
on 'wc -l raw/date=2025-09-15/*.jsonl'
on 'python transform.py 2025-09-15'
on 'python report.py 2025-09-15'

block trace
on 'python trace.py ST02 2025-09-15'
S
