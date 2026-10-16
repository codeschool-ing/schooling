#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt
#   python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1, section `the-lab`, builds. Every program run
# here is read out of this lesson's sections by lab/extract.py and lands in
# ~/roda/collect, the directory section `volume` tells the student to make, so
# the program run is the program printed.
#
# STAGED rather than typed: nothing. The late ride in `inc-after` is late by
# construction (app.py writes it with an old updated_at after the first copy),
# which is what the section says it stands for. The pseudonymisation key in
# `pseudo` is a lab value given on the command line, as the section says.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-059zqxhd <<'S'
cd collect

block volume
on 'python volume.py'

block sample-line
on 'head -1 sample.jsonl'

block poll
on 'python poll.py'

block inc-first
on 'python app.py morning'
on 'python incremental.py 0'
on 'python incremental.py 10'

block inc-after
on 'python app.py after'
on 'python incremental.py 0'
on 'python incremental.py 10'

block inc-compare
on 'python compare.py'

block door-15
on 'python deliver.py'
on 'python door.py 2025-09-15'

block quarantine
on 'cat quarantine-2025-09-15.csv'

block door-16
on 'python door.py 2025-09-16; echo $?'

block reconcile
on 'python reconcile.py'

block cost
on 'python cost.py'

block pseudo
on 'RODA_PSEUDO_KEY=lab-key-not-a-secret python pseudo.py'
S
