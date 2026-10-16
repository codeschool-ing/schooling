#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of deep-learning, as a script that
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
# what ran is what the page shows: seqtask.py is this lesson's, the rest are
# this lesson's own programs. Recorded on Ubuntu 24.04, Python 3.12.3, torch
# 2.14.1 on four processors and no graphics card, TZ=America/Sao_Paulo.
#
# recall.py and timing.py pin PyTorch to one thread, and say why in the lesson.
# The timings in the `timing` block depend on the machine and on what else it
# was doing; the lesson quotes their ratios, and the capture was repeated when
# a run looked disturbed by other work on the same processors.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-kv44h7v9
lab reset

use shapes.py
block shapes
on 'python shapes.py'

use rnn_by_hand.py
block rnn
on 'python rnn_by_hand.py'

use bptt.py
block bptt-rnn
on 'python bptt.py rnn'

use lstm_step.py
block lstm-step
on 'python lstm_step.py'

block bptt-lstm
on 'python bptt.py lstm'
on 'python bptt.py lstm 3'

use seqtask.py recall.py
block recall
on 'time python recall.py'

use timing.py
block timing
on 'python timing.py'
