#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of deep-learning, as a script that
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
# loop.py from lesson 9, cnn.py from lesson 11, pretrain.py from lesson 13, and
# this lesson's own. Recorded on Ubuntu 24.04, Python 3.12.3, four processors
# and no graphics card, TZ=America/Sao_Paulo, on 2026-10-16.
#
# STAGED: base.pt, which every program here reads, is written silently by
# lesson 13's pretrain.py before the first block, as lesson 13 told the student
# to do. Nothing downloads anything: the language-model code the last section
# shows is not run.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-hh3zyypf
lab reset

use digits.py tdigits.py loop.py cnn.py pretrain.py
quiet 'python pretrain.py'

use freeze.py
block freeze
on 'python freeze.py'

use depths.py
block depths
on 'python depths.py'

use rates.py
block rates
on 'python rates.py'

use forget.py
block forget
on 'python forget.py'

use lora.py adapt.py
block adapt
on 'python adapt.py'

use sizes.py
block sizes
on 'python sizes.py'
