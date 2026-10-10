#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of deep-learning, as a script that
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
# what ran is what the page shows: digits.py from lesson 1, and tdigits.py,
# loop.py, mlp.py and the rest from this lesson. Recorded on Ubuntu 24.04,
# Python 3.12.3, torch 2.14.1 on four processors and no graphics card,
# TZ=America/Sao_Paulo, on 2026-10-10.
#
# STAGED: nothing. load.py reads the mlp.pt that train.py, run above it, wrote.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-7vz462xb
lab reset

use digits.py tensors.py
block tensors
on 'python tensors.py'
block cuda
on "python -c \"import torch; torch.zeros(1, device='cuda')\""

use autograd.py
block autograd
on 'python autograd.py'

use mlp.py tdigits.py modules.py
block modules
on 'python modules.py'

use loop.py train.py
block train
on 'python train.py'

use bugs.py
for b in none zero_grad softmax eval item labels; do
  block "bug-$b"
  on "python bugs.py $b"
done

block mse
on "python -c \"import torch, torch.nn.functional as F; y = torch.arange(4.0); print(F.mse_loss(y.reshape(-1, 1), y), F.mse_loss(y, y))\""

use load.py
block load
on 'wc -c mlp.pt'
on 'python load.py'
