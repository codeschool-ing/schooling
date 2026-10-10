#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of deep-learning, as a script that
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
# loop.py from lesson 9, cnn.py from lesson 11, and this lesson's own.
# Recorded on Ubuntu 24.04, Python 3.12.3, four processors and no graphics
# card, TZ=America/Sao_Paulo, on 2026-10-10.
#
# NOTHING IS STAGED. base.pt, which transfer.py reads, is written by the
# `pretrain` block just above it, as the lesson tells the student to do.
# weights.py reads torchvision's own description of a pretrained model and
# downloads nothing; the download the lesson shows after it is not run.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-pwdkmvn9
lab reset

use digits.py tdigits.py loop.py cnn.py

use augment.py
block augment
on 'python augment.py'

use preserve.py
block preserve
on 'python preserve.py'

use augtrain.py
block augtrain
on 'python augtrain.py'

use pretrain.py
block pretrain
on 'python pretrain.py'
on 'ls -l base.pt'

use transfer.py
block transfer
on 'python transfer.py'

use weights.py
block weights
on 'python weights.py'
