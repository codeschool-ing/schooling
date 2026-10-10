#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of deep-learning, as a script that
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
# what ran is what the page shows: digits.py from lesson 1, tinynet.py from
# lesson 3, optim.py and fit.py from lesson 5, and the rest from this lesson.
# Recorded on Ubuntu 24.04, Python 3.12.3, four processors and no graphics
# card, TZ=America/Sao_Paulo, on 2026-10-10.
#
# STAGED: nothing. Every block runs on an emptied ~/dl with only the programs
# the lessons show written into it.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-53c4bdf1
lab reset

use digits.py tinynet.py optim.py fit.py small.py overfit.py
block overfit
on 'python overfit.py'

use decay.py
block decay
on 'python decay.py'

use dropout.py
block dropout
on 'python dropout.py'

use early.py
block early
on 'python early.py'

use shift.py
block shift
on 'python shift.py'

use compare.py
block compare
on 'python compare.py'
