#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of deep-learning, as a script that
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
# what ran is what the page shows: seqtask.py is lesson 14's, the rest are this
# lesson's own programs. Recorded on Ubuntu 24.04, Python 3.12.3, torch 2.14.1
# on four processors and no graphics card, TZ=America/Sao_Paulo.
#
# recall_tf.py pins PyTorch to one thread, as lesson 14's recall.py does, and
# the lesson says why. The seconds it prints depend on the machine and on what
# else it was doing; the accuracies do not.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-pna34k24
lab reset

use qkv.py
block qkv
on 'python qkv.py'

use attention.py
block attention
on 'python attention.py'

use causal.py
block causal
on 'python causal.py'

use heads.py
block heads
on 'python heads.py'

use positions.py
block positions
on 'python positions.py'

use block.py
block block
on 'python block.py'

use seqtask.py recall_tf.py
block recall-tf
on 'python recall_tf.py'

use where.py
block where
on 'python where.py'

block no-positions
on 'python recall_tf.py --no-positions'
