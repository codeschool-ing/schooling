#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of deep-learning, as a script that
# produces them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command
# and every program, and nothing here names a file the student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lessons' own sections through lab/shown.py:
# this lesson's, and digits.py (lesson 1), tdigits.py and loop.py (lesson 9)
# and cnn.py (lesson 11), which it uses. Recorded on Ubuntu 24.04, Python
# 3.12.3, four processors and no graphics card, TZ=America/Sao_Paulo.
#
# Every torchvision model here is built with weights=None, and the figures
# card.py and scaling.py print come from the metadata torchvision installs
# with itself: nothing is downloaded. The times small.py prints are wall-clock
# on this machine.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-tvaxtbhe
lab reset

use stack.py
block stack
on 'python stack.py'

use digits.py tdigits.py loop.py deep.py depth.py
block plain
on 'python depth.py Plain'

block residual
on 'python depth.py Residual'

use grads.py
block grads
on 'python grads.py'

use resnet.py
block resnet
on 'python resnet.py'

use separable.py
block separable
on 'python separable.py'

use scaling.py
block scaling
on 'python scaling.py'

use card.py
block card
on 'python card.py'

use cnn.py small.py
block small
on 'python small.py'
