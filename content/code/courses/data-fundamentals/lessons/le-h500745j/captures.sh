#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh
#
# The machine is the one lesson 1, section `the-lab`, builds. replicas.py and
# merge.py are read out of sections `a-partition` and `choosing-availability`
# by lab/extract.py and land in ~/roda/cap, the directory this lesson works in,
# so the program run is the program printed.
#
# Nothing is STAGED: the partition is a dictionary inside replicas.py, and no
# network, no second machine and no clock is involved. The output depends on
# nothing but the program text.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-h500745j <<'S'
cd cap
block cp
on 'python replicas.py cp'

block ap
on 'python replicas.py ap'

block merge
on 'python merge.py'
S
