#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of qa-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt && python3 ../../lab/splice.py . out.txt
#
# The machine is the one section `the-lab` builds: Ubuntu 24.04, ~/aurora with
# its .venv, and the lines that section adds to ~/.bashrc. tickets.py is read
# out of section `a-first-look` by lab/extract.py, so the program run is the
# program printed.
#
# STAGED rather than typed: `no-venv` runs on the machine before the setup,
# where python3-venv is not installed yet. `not-active` is a shell started
# without ~/.bashrc, which is what a terminal opened before the setup's last
# step is; the prompt lines in it are printed by this script, since the shell
# they stand for is not an interactive one.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, behave 1.3.3, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB bare <<'S'
block no-venv
on 'python3 -m venv .venv'
S

bash $LAB run le-0rz35yja <<'S'
block check
on 'python --version'
on 'which python'
on 'behave --version'

block disk
on 'du -sh .venv'

block not-active
printf 'lia@lab:~/aurora$ %s\n' 'python3 -c "import behave"'
env -i HOME=/home/lia USER=lia LANG=C.UTF-8 PATH=/usr/bin:/bin bash -c 'cd ~/aurora && python3 -c "import behave"' 2>&1
printf 'lia@lab:~/aurora$ %s\n' 'source .venv/bin/activate'
printf 'lia@lab:~/aurora$ %s\n' 'python3 -c "import behave"'
env -i HOME=/home/lia USER=lia LANG=C.UTF-8 PATH=/usr/bin:/bin bash -c 'cd ~/aurora && source .venv/bin/activate && python3 -c "import behave"' 2>&1

block no-version
on 'pip install behave==1.3.9 2>&1 | tail -2'

block first
on 'python tickets.py 35 no thu 20:00'
on 'python tickets.py 20 yes thu 20:00'
on 'python tickets.py 8 no sat 14:00'
on 'python tickets.py 35 no wed 20:00'

block sixty
on 'python tickets.py 61 no thu 20:00'
on 'python tickets.py 60 no thu 20:00'
S
