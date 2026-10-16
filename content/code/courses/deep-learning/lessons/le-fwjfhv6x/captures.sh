#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of deep-learning, as a script that
# produces them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command
# and every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons' own sections through lab/shown.py, so
# what ran is what the page shows: digits.py from lesson 1, tdigits.py, loop.py
# and mlp.py from lesson 9, cnn.py from lesson 11, and this lesson's own.
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1 and torch 2.14.1
# on the processor, four processors and no graphics card, TZ=America/Sao_Paulo,
# on 2026-10-16.
#
# Nothing is staged. The seconds in `cancer`, `churn` and `baseline` are wall
# time on one processor (the programs ask for one), on a machine other work was
# sharing; the lesson reads their order and ratios, not their digits.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-fwjfhv6x
lab reset

use digits.py loop.py bench.py cancer.py
block cancer
on 'python cancer.py'

use table.py churn.py
block churn
on 'python churn.py'

use tdigits.py mlp.py cnn.py small.py
block small
on 'python small.py'

use baseline.py
block baseline
on 'python baseline.py'

use moved.py
block moved
on 'python moved.py'
