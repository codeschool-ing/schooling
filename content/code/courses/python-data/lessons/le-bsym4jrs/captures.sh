#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of python-data, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, by ../../lab/fill.py, and
# `fill.py --check` holds the lesson to it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l01.txt
#   python3 ../../lab/fill.py --check . /tmp/l01.txt
#
# What is STAGED rather than typed: the lab, built by lab.sh from the-lab.md's
# own commands, and make_data.py, which lab.sh copies out of your-data.md. The
# notebook in the-file.md was made by the cells of first-notebook.md, written
# with nbformat and run with `jupyter nbconvert --execute`, where a student
# types the same cells into JupyterLab and runs them with Shift+Enter. nbconvert
# is told not to record timings, which JupyterLab does not record either; the
# cell ids are random, in a student's notebook as in this one.
# `oldpy` is a second project on the same machine, made with Ubuntu's Python
# 3.11 to show what an interpreter too old for the pins prints; a fresh Ubuntu
# 24.04 has no 3.11, and the section says so. That 3.11 is not Ubuntu's own and
# its pip does not read the system's certificates, so it is pointed at them
# with PIP_CERT; and its "new version of pip" notice is turned off, because a
# student's would name a different version on a different day.
#
# Blocks whose name ends in `~` carry a server's token and its clock.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-$(dirname "$0")/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf '(.venv) ana@lab:~/pydata$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
bare() { printf 'ana@lab:~$ %s\n' "$*"; lab raw "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null

block py3
bare python3 --version

block check
on python --version
on 'python -c "import numpy, pandas, matplotlib, seaborn; print(numpy.__version__, pandas.__version__, matplotlib.__version__, seaborn.__version__)"'
on jupyter lab --version

block start~
lab exec 'timeout -s INT -k 2 6 jupyter lab 2>&1' | sed -n '/Serving notebooks/,/Use Control-C/p'

block size
on du -sh .venv

lab exec 'rm -f stations.csv weather.csv trips.csv'
block make
on python make_data.py

block look
on ls -l
on head -3 stations.csv weather.csv trips.csv

# --- the failures ---------------------------------------------------------

# What an interactive shell says, rather than `bash -c`, which adds "line 1".
block not-active
printf 'ana@lab:~$ %s\n' 'cd pydata'
printf 'ana@lab:~/pydata$ %s\n' 'jupyter lab'
lab raw 'echo "cd pydata && jupyter lab" | bash -i 2>&1 | grep "not found"' || true

block outside
printf 'ana@lab:~/pydata$ %s\n' 'python3 -m pip install pandas==3.0.6'
lab raw 'cd pydata && python3 -m pip install pandas==3.0.6 2>&1 | head -3' || true

block old
lab raw 'rm -rf oldpy && mkdir oldpy && cd oldpy && python3.11 -m venv .venv' >/dev/null
printf '(.venv) ana@lab:~/oldpy$ %s\n' 'python --version'
lab raw 'cd oldpy && source .venv/bin/activate && python --version' 2>&1
printf '(.venv) ana@lab:~/oldpy$ %s\n' 'pip install numpy==2.5.3'
lab raw 'cd oldpy && source .venv/bin/activate && PIP_CERT=/etc/ssl/certs/ca-certificates.crt pip install --disable-pip-version-check numpy==2.5.3 2>&1'
lab raw 'rm -rf oldpy'

block port~
lab exec 'setsid jupyter lab --no-browser </dev/null >/dev/null 2>&1 & sleep 5'
lab exec 'timeout -s INT -k 2 6 jupyter lab 2>&1' | grep -E 'already in use|is running at|^\S.*http://localhost'
# Anchored on the interpreter's path, so it cannot match this script's own shell.
pkill -KILL -u ana -f '^/home/ana/pydata/.venv/bin/python3 /home/ana/pydata/.venv/bin/jupyter-lab' || true

# --- the-file: the notebook first-notebook.md's cells make ---------------
lab exec "python - '$PWD/first-notebook.md' <<'PY'
import re, sys, nbformat
text = open(sys.argv[1], encoding='utf-8').read()
cells = re.findall(r'^\`\`\`python\n(.*?)^\`\`\`$', text, re.S | re.M)
nb = nbformat.v4.new_notebook()
nb.cells = [nbformat.v4.new_code_cell(c.rstrip('\n')) for c in cells]
nb.metadata['kernelspec'] = {'display_name': 'Python 3 (ipykernel)', 'language': 'python', 'name': 'python3'}
nbformat.write(nb, 'first.ipynb')
PY
jupyter nbconvert --to notebook --execute --inplace --ExecutePreprocessor.record_timing=False first.ipynb >/dev/null 2>&1"

block file-head
on ls -l first.ipynb
on head -n 24 first.ipynb

block file-outputs
on sed -n 69,98p first.ipynb

block file-tail
on tail -n 22 first.ipynb
