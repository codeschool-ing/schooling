#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it and splicing the result:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt
#   python3 ../../lab/splice.py . out.txt
#
# The machine is lesson 1's lab: Ubuntu 24.04, ~/roda with its .venv and the
# lines lesson 1 adds to ~/.bashrc. Every program run here is read out of this
# lesson's sections by lab/extract.py into ~/roda/formats, so the program run
# is the program printed. The blocks run in the order the sections print them,
# because `one-column` and `squeeze` read the files `five` writes.
#
# STAGED: nothing. Every file the transcripts read is written by a program the
# lesson prints, from the fixed seed in rides.py. The one-liners in `latin1`
# and `avro-header` are printed in the sections as the commands they are.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-wpv0krd2 <<'S'
cd formats

block rides
on 'python rides.py'

block comma
on 'python comma.py'
on 'cat notes.csv'

block latin1
on "python -c \"print(open('notes.csv', encoding='latin-1').read().splitlines()[1])\""

block json
on 'python as_json.py'

block parquet
on 'python as_parquet.py'

block avro
on 'python as_avro.py'

block avro-header
on "python -c \"print(open('rides.avro', 'rb').read(100))\""

block orc
on 'python as_orc.py'

block five
on 'python five.py'

block one-column
on 'python one_column.py'

block squeeze
on 'python squeeze.py'

block evolve
on 'python evolve.py'

block shifted
on 'python shifted.py'
S
