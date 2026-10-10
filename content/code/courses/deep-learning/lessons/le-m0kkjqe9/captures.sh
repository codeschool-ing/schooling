#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of deep-learning, as a script that
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
# loop.py from lesson 9, and exp.py, track.py and the rest from this lesson.
# Recorded on Ubuntu 24.04, Python 3.12.3, git 2.43.0, four processors and no
# graphics card, TZ=America/Sao_Paulo, on 2026-10-10.
#
# STAGED: nothing in ~/dl. The two `git config --global` commands the lesson
# shows write /home/ana/.gitconfig, which `lab reset` leaves in place; running
# them again rewrites the same two values. A commit's hash depends on the time
# it was made, so a rerun prints different hashes and the same accuracies.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-m0kkjqe9
lab reset

block init
on 'python -c "import torch; torch.manual_seed(0); print(torch.nn.Linear(64, 32).weight[0, :3])"'
on 'python -c "import torch; torch.manual_seed(0); print(torch.nn.Linear(64, 32).weight[0, :3])"'
on 'python -c "import torch; torch.manual_seed(1); print(torch.nn.Linear(64, 32).weight[0, :3])"'

use digits.py tdigits.py loop.py exp.py seeds.py
block seeds
on 'python seeds.py'

use spread.py
block spread
on 'python spread.py'

use .gitignore track.py run.py
block git
on 'git config --global user.name "Ana"'
on 'git config --global user.email "ana@example.com"'
on 'git init -b main'
on 'git add .'
on 'git status --short'
on 'git commit -q -m "Train the digits network and record every run"'
on 'git log --oneline'

block record
on 'python run.py'
on 'tail -n 1 runs.jsonl | python -m json.tool'

block dirty
on "echo '# trying something' >> exp.py"
on 'python run.py'
on 'git checkout exp.py'
on 'git status --short'

block compare
on 'for s in 0 1 2 3 4; do python run.py --seed $s; done'
on 'for s in 0 1 2 3 4; do python run.py --seed $s --hidden 64; done'
on 'for s in 0 1 2 3 4; do python run.py --seed $s --lr 0.05; done'

use report.py
block report
on 'python report.py'
on 'git add report.py'
on 'git commit -q -m "Report the runs by configuration"'
on 'git log --oneline'

use order.py
block order
on 'python order.py'

use threads.py
block threads
on 'python threads.py'

block tensorboard
on 'python -c "from torch.utils.tensorboard import SummaryWriter"'
