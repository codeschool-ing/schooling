#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of deep-learning, as a script that
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
# and mlp.py from lesson 9, and dset.py, warp.py and the rest from this lesson.
# Recorded on Ubuntu 24.04, Python 3.12.3, torch 2.14.1 on four processors and
# no graphics card, TZ=America/Sao_Paulo.
#
# TIMINGS. The blocks slow, workers and waiting print times measured on the
# capture machine, and their numbers move from run to run and from machine to
# machine. The prose quotes them; rerun all three on a quiet machine before
# re-reading the numbers it quotes.
#
# STAGED: nothing.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-zqcyvt3p
lab reset

use digits.py tdigits.py dset.py firstset.py
block firstset
on 'python firstset.py'

use batches.py
block batches
on 'python batches.py'

use loop.py mlp.py ltrain.py
block ltrain
on 'python ltrain.py'

use warp.py slow.py
block slow
on 'python slow.py'

use workers.py
block workers
on 'nproc'
on 'python workers.py'

use twins.py
block twins
on 'python twins.py'

use waiting.py
block waiting
on 'python waiting.py'

use todevice.py
block todevice
on 'python todevice.py'
block pinned
on "python -c \"from torch.utils.data import DataLoader; from dset import Digits; xb, yb = next(iter(DataLoader(Digits('train'), batch_size=32, pin_memory=True))); print('pinned:', xb.is_pinned())\""
