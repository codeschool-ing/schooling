#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of deep-learning, as a script that
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
# lesson 3, and this lesson's six programs. Recorded on Ubuntu 24.04, Python
# 3.12.3, four processors and no graphics card, TZ=America/Sao_Paulo, on
# 2026-10-10.
#
# STAGED: nothing. Each block starts from a ~/dl holding only the files `use`
# wrote into it.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-4ts2gwx4
lab reset

use regression_losses.py
block regression
on 'python regression_losses.py'

use xent.py
block xent
on 'python xent.py'

use digits.py tinynet.py stable.py
block stable
on 'python stable.py'

use multilabel.py
block multilabel
on 'python multilabel.py'

use mse_vs_ce.py
block mse-vs-ce
on 'python mse_vs_ce.py'

use metric.py
block metric
on 'python metric.py'
