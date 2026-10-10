#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of deep-learning, as a script that
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
# what ran is what the page shows. Recorded on Ubuntu 24.04, Python 3.12.3, four
# processors and no graphics card, TZ=America/Sao_Paulo, on 2026-10-10.
#
# STAGED: the `bare` block runs in a shell where the virtual environment was
# never activated, which is what a terminal opened before the ~/.bashrc line
# looks like, with Ubuntu 24.04's own python3 (3.12) first on its PATH.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-6ps2dmva
lab reset

block checks
on 'python --version'
on 'which python'
on 'python -c "import torch; print(torch.__version__, torch.cuda.is_available())"'
on 'du -sh .venv'

block no-venv
bare 'python3 -c "import torch"'

use digits.py look.py
block look
on 'python look.py'

use perceptron.py
block perceptron
on 'python perceptron.py'

use activations.py
block activations
on 'python activations.py'

use layer.py
block layer
on 'python layer.py'

use xor.py
block xor
on 'python xor.py'
