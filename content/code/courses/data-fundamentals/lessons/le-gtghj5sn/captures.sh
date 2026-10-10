#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt
#   python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds. The programs under ~/roda/spread are
# read out of this lesson's sections by lab/extract.py, so the program run is
# the program printed. Everything they measure is generated from fixed seeds or
# is plain arithmetic, so the numbers are the same on every run.
#
# STAGED rather than typed: section `failures` tells the student to start
# nodes.py in a second terminal; here it is started in the background before
# the probes and killed after them, and its own output (none) is not shown.
# The two pretend nodes listen on 127.0.0.1 only. retry.py's lost replies and
# replica.py's 800 ms of lag are simulated inside the programs, and the prose
# says so.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-gtghj5sn <<'S'
cd spread

block skew
on 'python skew.py'

block rebalance
on 'python rebalance.py'

block replica
on 'python replica.py'

block quorum
on 'python quorum.py'

block probe
~/roda/.venv/bin/python nodes.py >/dev/null 2>&1 &
sleep 1
on 'python probe.py 1'
on 'python probe.py 5'
kill %1

block retry
on 'python retry.py'

block shuffle
on 'python shuffle.py'
S
