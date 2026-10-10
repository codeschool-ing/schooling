#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of data-fundamentals, as a script
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
# TZ=America/Sao_Paulo. The programs run are read out of this lesson's English
# sections by lab/extract.py, so the program run is the program printed:
# freshness.py and month.py from `promises-about-data`, matrix.py from
# `a-scoring-matrix`, cost.py from `what-it-costs`, all in ~/roda/choose.
#
# STAGED rather than typed: the four files under landing/ stand for four feeds,
# and their modification times are set by freshness.py itself with os.utime,
# relative to a fixed "now" of 09:00 on Monday 6 October 2025. month.py
# simulates September 2025 from a fixed seed. Every price in cost.py is
# invented and the lesson says so. `nudged` makes its file with sed, as the
# section's command does.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-bxjt5117 <<'S'
cd choose

block freshness
on 'python freshness.py'
on 'ls -l --time-style=long-iso landing'

block month
on 'python month.py'

block matrix
on 'python matrix.py'

block nudged
on 'sed "s/\[3, 2, 5, 5, 2\]/[4, 2, 5, 5, 2]/" matrix.py > nudged.py'
on 'python nudged.py | head -4'

block cost
on 'python cost.py'
S
