#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of deep-learning, as a script that
# produces them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command
# and every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lesson's own sections through lab/shown.py, so
# what ran is what the page shows. digits.py is lesson 1's, tinynet.py lesson
# 3's, optim.py and fit.py lesson 5's: the lesson tells the student they already
# have them, and this script writes them into ~/dl as those lessons show them.
# Recorded on Ubuntu 24.04, Python 3.12.3, four processors and no graphics card,
# TZ=America/Sao_Paulo, on 2026-10-10.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-4j45eqhv
lab reset

use digits.py tinynet.py optim.py fit.py

use scale.py
block scale
on 'python scale.py'

use batchnorm.py checknorm.py
block checknorm
on 'python checknorm.py'

use deep.py
block deep-none
on 'python deep.py none'
block deep-batch
on 'python deep.py batch'

use predict.py
block predict
on 'python predict.py'

use layernorm.py
block checkln
on 'python -c "from checknorm import check; from layernorm import LayerNorm; check(LayerNorm(5), axis=1)"'

use alone.py
block alone
on 'python alone.py'

block deep-layer
on 'python deep.py layer'
