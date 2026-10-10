#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of deep-learning, as a script that
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
# NO TIMINGS ARE QUOTED. The recording machine was running other work, which
# made seconds meaningless for a program this small; the lesson counts steps
# and images instead, which no machine changes.
#
# STAGED: nothing. Every block runs on an emptied ~/dl with only the programs
# the lessons show written into it.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-x43yft24
lab reset

use digits.py tinynet.py optim.py fit.py steps.py
block steps
on 'python steps.py'

use batchsize.py
block by-epochs
on 'python batchsize.py epochs'
block by-steps
on 'python batchsize.py steps'

use batch_lr.py
block batch-lr
on 'python batch_lr.py'

use curve.py
block curve
on 'python curve.py'

use four.py
block small
on 'python four.py small'
block few
on 'python four.py few'
block fast
on 'python four.py fast'
block shuffled
on 'python four.py shuffled'
