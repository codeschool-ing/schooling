#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l4.txt
#   python3 ../../lab/paste.py --check . /tmp/l4.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, and feira.py as lesson 2
# prints it. Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/the-obvious-one.md" obvious.py
save "$HERE/the-subtle-one.md" subtle.py
save "$HERE/the-subtle-one.md" leak_test.py
save "$HERE/preparation-leak.md" noise.py
save "$HERE/how-it-looks.md" suspects.py

block obvious
on 'python obvious.py'
block subtle
on 'python subtle.py'
block leak-test
on 'python leak_test.py'
block noise
on 'python noise.py'
block suspects
on 'python suspects.py'
