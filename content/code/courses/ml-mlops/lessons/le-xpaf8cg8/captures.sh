#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh > out.txt   # builds the lab from nothing, then records
#
# It starts by removing ana and the venv package, and builds them again with
# the steps lesson 1 shows, so that the setup sections record a real first
# install, and the failures a student meets on the way: venv without its
# package, pip outside the environment, the environment not active, and a
# program run from the wrong directory.
#
# A line that starts with ana@dev:~$ or ana@dev:~/ml$ is what ana typed and
# what it printed. What is STAGED rather than typed, and not shown: the lab's
# own steps (lab.sh), and the files ana saved (stage below), each of which the
# lesson shows whole and is read out of it. The apt and pip installs run but
# their output is not quoted; the checks after them are.
#
# MEASURED AND QUOTED WITHOUT A TRANSCRIPT: the disk the environment takes once
# every library the course installs is in it (your-machine). It is measured
# in a throwaway environment, ~/sizecheck, built with every pip line of the
# course and deleted afterwards.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9

quiet lab purge
quiet apt-get remove -y python3.12-venv sqlite3
quiet lab user

block when-setup-fails
bare 'python3 -m venv ~/mlenv'
quiet rm -rf /home/ana/mlenv

quiet lab system
quiet lab venv

block installing
home 'python --version'
home "pip list 2>/dev/null | grep -E '^(numpy|pandas|scikit-learn|scipy) '"

block when-setup-fails
bare 'pip install scikit-learn==1.9.1'

quiet lab exec 'mkdir -p ~/ml'
stage generate.py le-xpaf8cg8/the-shop.md
block the-shop
on 'python generate.py'
block the-shop
on 'sqlite3 -header -column shop.db "SELECT * FROM members LIMIT 3"'
on 'sqlite3 -header -column shop.db "SELECT * FROM purchases WHERE member_id = 2"'
on 'sqlite3 -header -column shop.db "SELECT * FROM lines JOIN titles USING (title_id) WHERE purchase_id = 12"'

block when-setup-fails
bare 'cd ~/ml && python3 generate.py'

stage features.py le-xpaf8cg8/supervised.md
stage supervised.py le-xpaf8cg8/supervised.md
block when-setup-fails
home 'python ml/supervised.py 2>&1 | tail -n 3'
home 'ls -l shop.db'
quiet lab exec 'rm -f ~/shop.db'

block supervised
on 'python supervised.py'

stage unsupervised.py le-xpaf8cg8/unsupervised.md
block unsupervised
on 'python unsupervised.py'

stage bandit.py le-xpaf8cg8/reinforcement.md
block reinforcement
on 'python bandit.py'

# the size of everything the course installs, without a transcript
quiet lab exec 'python3 -m venv ~/sizecheck && ~/sizecheck/bin/pip install -q numpy==2.5.3 pandas==3.0.6 scikit-learn==1.9.1 scipy==1.18.1 mlflow==3.17.0 dvc==3.67.1 fastapi==0.143.0 uvicorn==0.54.0 skl2onnx==1.20.0 onnxruntime==1.31.0'
echo "# disk-all: $(lab exec 'du -sh ~/sizecheck' | cut -f1)" >&2
quiet lab exec 'rm -rf ~/sizecheck'
