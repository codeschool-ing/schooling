#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh
#
# The machine is the one section `the-lab` builds: Ubuntu 24.04, ~/roda with
# its .venv, and the lines that section adds to ~/.bashrc. first.py is read out
# of section `a-first-look` by lab/extract.py, so the program run is the
# program printed.
#
# STAGED rather than typed: `no-venv` runs on the machine before the setup,
# where python3-venv is not installed yet. `not-active` is a shell started
# without ~/.bashrc, which is what a terminal opened before the setup's last
# step is; the prompt lines in it are printed by this script, since the shell
# they stand for is not an interactive one. `renamed` and `twice` make their
# file with sed, as the section's command does.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB bare <<'S'
block no-venv
on 'python3 -m venv .venv'
S

bash $LAB run le-tgvfkfr9 <<'S'
block check
on 'python --version'
on 'which python'
on 'python -c "import pyarrow, fastavro; print(pyarrow.__version__, fastavro.__version__)"'
on 'date +%Z'

block disk
on 'du -sh .venv'
on 'du -sh .venv/lib/python3.12/site-packages/* | sort -h | tail -3'

block not-active
printf 'ana@lab:~/roda$ %s\n' 'python3 -c "import pyarrow"'
env -i HOME=/home/ana USER=ana LANG=C.UTF-8 PATH=/usr/bin:/bin bash -c 'cd ~/roda && python3 -c "import pyarrow"' 2>&1
printf 'ana@lab:~/roda$ %s\n' 'source .venv/bin/activate'
printf 'ana@lab:~/roda$ %s\n' 'python3 -c "import pyarrow"'
env -i HOME=/home/ana USER=ana LANG=C.UTF-8 PATH=/usr/bin:/bin bash -c 'cd ~/roda && source .venv/bin/activate && python3 -c "import pyarrow"' 2>&1

block no-version
on 'pip install pyarrow==99.0.0 2>&1 | tail -2'

block first
on 'python first.py'

block renamed
on 'sed "s/,start_station,started_at/,start,started_at/" first.py > renamed.py'
on 'python renamed.py'

block twice
on 'sed "/^R000002/p" first.py > twice.py'
on 'python twice.py'
S
