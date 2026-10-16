#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l7.txt
#   python3 ../../lab/paste.py --check . /tmp/l7.txt
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
save "$HERE/how-a-tree-splits.md" first_tree.py
save "$HERE/purity.md" purity.py
save "$HERE/depth.md" depth.py
save "$HERE/pruning.md" pruning.py
save "$HERE/regression-trees.md" tree_minutes.py
save "$HERE/instability.md" unstable.py

block first-tree
on 'python first_tree.py'
block purity
on 'python purity.py'
block depth
on 'python depth.py'
block pruning
on 'python pruning.py'
block tree-minutes
on 'python tree_minutes.py'
block unstable
on 'python unstable.py'
