#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of gcp-data (Firestore), as a
# script that produces them. Every transcript in the lesson was copied from its
# output.
#
#   sudo WHEELS=/var/tmp/gcplab/wheels-le-gjsnmk71 bash ../../lab.sh run captures.sh
#
# THE EMULATORS ARE STARTED WITH THE COMMANDS THE LESSON GIVES, as the student
# starts them in terminals of their own; here they run in the background. The
# Native-mode one is lab.sh's `firestore`; the Datastore-mode one, on 8081, is
# the last line of the second ```sh fence of composite-indexes.md. seed.py and
# query.py are the schooling-examples, and the other programs and index.yaml are
# the fences their files introduce, all read out of the lesson as they stand.
#
# NOTHING HERE IS BILLED OR MEASURED. The composite-index refusal of Google
# Cloud, Query Explain's metrics, the index commands (`gcloud firestore indexes
# …`, which go to an admin service with no emulator) and the bill are taught
# from Google's documentation and pricing page.
#
# STAGED: `pip install -q google-cloud-datastore==2.27.0` installs from wheels
# fetched beforehand with `pip download` into WHEELS (the run has no network).
# Which customer wins in stock.py is timing, and can differ between runs.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$HERE"
emu_start firestore || exit 1

# ---- documents-and-collections ------------------------------------------------
example "$L/documents-and-collections.md" seed.py seed.py
block seed
run 'python3 seed.py'
block read
run "python3 -c \"from google.cloud import firestore; print(firestore.Client(project='planner-dev').document('customers/c-17').get().to_dict())\""
run "python3 -c \"from google.cloud import firestore; print([c.id for c in firestore.Client(project='planner-dev').document('customers/c-17').collections()])\""
block big
run "python3 -c \"from google.cloud import firestore; firestore.Client(project='planner-dev').document('customers/c-17').set({'notes': 'x' * 1100000})\" 2>&1 | tail -1"

# ---- single-field-indexes -----------------------------------------------------
example "$L/single-field-indexes.md" query.py query.py
block single
for q in one-customer pending big coffee; do run "python3 query.py $q"; done

# ---- composite-indexes --------------------------------------------------------
block composite
for q in pending-biggest lapa-late-october; do run "python3 query.py $q"; done
file_fence "$L/composite-indexes.md" explain.py > explain.py
block explain
run 'python3 explain.py'
file_fence "$L/composite-indexes.md" index.yaml > index.yaml
file_fence "$L/composite-indexes.md" ds.py > ds.py
run 'pip install -q google-cloud-datastore==2.27.0' > /dev/null
DS_CMD=$(fence "$L/composite-indexes.md" 2 | tail -1)
( cd ~/gcp && setsid bash -c "echo \$\$ > ~/.emu-ds.pid; exec $DS_CMD" > ~/.emu-ds.log 2>&1 < /dev/null & )
for _ in $(seq 240); do (exec 3<>/dev/tcp/127.0.0.1/8081) 2>/dev/null && break; sleep 0.25; done; sleep 1
block datastore
run 'DATASTORE_EMULATOR_HOST=localhost:8081 python3 ds.py'

# ---- transactions-and-cursors -------------------------------------------------
file_fence "$L/transactions-and-cursors.md" stock.py > stock.py
file_fence "$L/transactions-and-cursors.md" pages.py > pages.py
block stock
run 'python3 stock.py'
run 'python3 stock.py'
block pages
run 'python3 pages.py'

# ---- modes-and-price ----------------------------------------------------------
file_fence "$L/modes-and-price.md" price.py > price.py
block price
run 'python3 price.py'
kill -- -"$(cat ~/.emu-ds.pid)" 2>/dev/null
