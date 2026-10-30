#!/usr/bin/env bash
# The terminal session quoted in lesson 13 of gcp-foundations, as a script that
# produces it. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). sud.py is
# read out of the example in "sustained-use". The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
# The price 0.10 is an example the prose names as one, not a price Google
# charges.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: any bill, any SKU line, and any
# commitment.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

example "$HERE/sustained-use.md" sud.py > ~/gcp/sud.py || exit 1
block sud
for s in 0.25 0.5 0.75 1; do run "python3 sud.py 0.10 $s"; done
