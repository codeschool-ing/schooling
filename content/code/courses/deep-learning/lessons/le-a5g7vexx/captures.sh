#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of deep-learning, as a script that
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
# what ran is what the page shows: digits.py from lesson 1, tdigits.py and
# loop.py from lesson 9, and this lesson's own, cnn.py among them. Recorded on
# Ubuntu 24.04, Python 3.12.3, torch 2.14.1 on the processor, four processors
# and no graphics card, TZ=America/Sao_Paulo, on 2026-10-10.
#
# Nothing is staged: `filters` reads the cnn.pt that `compare` wrote, in the
# same ~/dl, which is what the student's machine has after the same two runs.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-a5g7vexx
lab reset

use digits.py filter.py
block filter
on 'python filter.py'

use shapes.py
block shapes
on 'python shapes.py'

use pool.py
block pool
on 'python pool.py'

use params.py
block params
on 'python params.py'

use cnn.py
block model
on 'python -c "import cnn; print(cnn.make_cnn())"'

use tdigits.py loop.py compare.py
block compare
on 'python compare.py'

use filters.py
block filters
on 'python filters.py'
