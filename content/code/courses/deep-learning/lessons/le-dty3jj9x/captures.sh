#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of deep-learning, as a script that
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
# lesson 3, and optim.py, fit.py and the rest from this lesson. Recorded on
# Ubuntu 24.04, Python 3.12.3, four processors and no graphics card,
# TZ=America/Sao_Paulo, on 2026-10-10.
#
# STAGED: nothing. Every block runs on an emptied ~/dl with only the programs
# the lessons show written into it.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-dty3jj9x
lab reset

use digits.py tinynet.py noise.py
block noise
on 'python noise.py'

use bowl.py
block bowl
on 'python bowl.py'

use adam_steps.py
block adam
on 'python adam_steps.py'

use optim.py fit.py train.py
block train
on 'python train.py'

use sweep.py
block sweep
on 'python sweep.py'

use schedules.py
block schedules
on 'python schedules.py'
