#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of deep-learning, as a script that
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
# what ran is what the page shows: digits.py from lesson 1, and tinynet.py and
# the rest from this lesson. Recorded on Ubuntu 24.04, Python 3.12.3, four
# processors and no graphics card, TZ=America/Sao_Paulo, on 2026-10-10.
#
# Nothing is staged: every file in ~/dl is one a lesson shows.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-9f3vvxn5
lab reset

use chain.py
block chain
on 'python chain.py'

use byhand.py
block byhand
on 'python byhand.py'

use tinynet.py again.py
block again
on 'python again.py'

use digits.py gradcheck.py
block gradcheck
on 'python gradcheck.py'

use train.py
block train
on 'python train.py'

use vanish.py
block vanish
on 'python vanish.py'
