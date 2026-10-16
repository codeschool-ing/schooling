#!/usr/bin/env bash
# The terminal sessions and program outputs quoted in lesson 1 of
# bi-techniques, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript
# and every example's output in this lesson was copied from running it:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: ana's account and ~/bi holding
# panela.py, which the lesson has the student save from the page. Everything
# after that is typed as the lesson shows it, starting from no virtual
# environment at all. pip downloads the packages from the Python Package
# Index, so this needs the network once.
#
# Recorded on Ubuntu 24.04, Python 3.13, pandas 3.0.6, statsmodels 0.15.0,
# scikit-learn 1.9.1, 4 cores, TZ=America/Sao_Paulo, on 2026-10-10.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab-capture.sh"

lab up >/dev/null
lab exec 'find . -mindepth 1 -maxdepth 1 ! -name panela.py -exec rm -rf {} +'

block setup
on 'python3 --version'
on 'python3 -m venv .venv'
on '.venv/bin/pip install --quiet pandas==3.0.6 statsmodels==0.15.0 scikit-learn==1.9.1'
on '.venv/bin/python -c "import pandas, statsmodels, sklearn; print(pandas.__version__, statsmodels.__version__, sklearn.__version__)"'

# The failure of running a program before its data exists comes first,
# because once panela.py has run the files are there.
save "$HERE/a-first-look.md" look.py
block failures
on '.venv/bin/python look.py'
on 'python3 -c "import pandas, statsmodels, sklearn"'
on '.venv/bin/python lok.py'

block data
on 'python3 panela.py'
on 'head -4 daily_orders.csv'

block first-look
on '.venv/bin/python look.py'
