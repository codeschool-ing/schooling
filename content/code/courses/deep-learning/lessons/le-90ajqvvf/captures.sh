#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of deep-learning, as a script that
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
# and mlp.py from lesson 9, cnn.py and compare.py from lesson 11, and work.py,
# memory.py and the rest from this lesson. Recorded on Ubuntu 24.04, Python
# 3.12.3, torch 2.14.1 on four processors and no graphics card,
# TZ=America/Sao_Paulo, on 2026-10-16.
#
# TIMINGS. The blocks `work` (the ms and GFLOP/s lines and the time ratio),
# `mixed` (the seconds column), `compare` (the `time` lines) and `bill` (its
# first line, which is fed the `real` time of `compare`) measure the clock, and
# the prose reads them as ratios and orderings. Every other number is arithmetic
# or a seeded training run and does not depend on the load of the machine.
#
# STAGED: nothing. `bill` is run with the seconds of the `real` line printed by
# `compare` just above it, rounded to a whole second, which is what the lesson
# tells the student to type.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-90ajqvvf
lab reset

use digits.py tdigits.py loop.py mlp.py cnn.py work.py
block work
on 'python work.py'

use memory.py
block memory
on 'python memory.py'

use precision.py
block precision
on 'python precision.py'

use mixed.py
block mixed
on 'python mixed.py'

use trap.py
block trap
on 'python trap.py'

use accumulate.py
block accumulate
on 'python accumulate.py'

use compare.py bill.py
block compare
out=$(on 'time python compare.py')
printf '%s\n' "$out"
secs=$(printf '%s\n' "$out" | awk '/^real/ { split($2, a, /[ms]/); printf "%.0f", a[1] * 60 + a[2] }')
block bill
on "python bill.py $secs"

use returns.py
block returns
on 'python returns.py'
