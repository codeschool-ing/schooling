#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of python-data, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, by ../../lab/fill.py, and
# `fill.py --check` holds the lesson to it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l03.txt
#   python3 ../../lab/fill.py --check . /tmp/l03.txt
#
# What is STAGED rather than typed: requirements.txt and check.py, which the
# lesson shows in full, are written from the lesson's own fences. `oldpandas`
# and `rebuilt` are two more folders on the same machine. Miniforge's
# installer is run with -b, which answers its questions with the defaults a
# person would accept; and ~/.condarc points conda at the system's
# certificates, because the machine this was recorded on reaches the network
# through a proxy with its own authority. pip's "new version" notice is turned
# off, as in lesson 1.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf '(.venv) ana@lab:~/pydata$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
at() { local dir=$1; shift; printf '(.venv) ana@lab:~/%s$ %s\n' "$dir" "$*"; lab raw "cd $dir && source .venv/bin/activate && $*" 2>&1 || true; }
cdon() { local env=$1 dir=$2; shift 2; printf '(%s) ana@lab:%s$ %s\n' "$env" "$dir" "$*"; lab raw "source ~/miniforge3/bin/activate && { [ $env = base ] || conda activate $env; } && cd $dir && $*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
fence() { python3 - "$HERE/$1" "$2" "$3" <<'PY'
import re, sys
text, lang, n = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2], int(sys.argv[3])
sys.stdout.write(re.findall(r"^```" + lang + r"\n(.*?)^```$", text, re.S | re.M)[n])
PY
}
export PIP_DISABLE_PIP_VERSION_CHECK=1
lab reset >/dev/null
lab raw 'rm -rf oldpandas rebuilt ~/.local/share/jupyter/kernels/oldpandas' >/dev/null

# --- requirements ----------------------------------------------------------
block freeze
on 'pip freeze | wc -l'
on 'pip freeze | grep -E "^(numpy|pandas|python-dateutil|pytz|tzdata)=="'

fence requirements.md '' 0 | lab exec 'cat > requirements.txt'
block rebuild
printf 'ana@lab:~$ %s\n' 'mkdir rebuilt && cd rebuilt'
lab raw 'mkdir rebuilt && cp pydata/requirements.txt rebuilt/'
printf 'ana@lab:~/rebuilt$ %s\n' 'python3 -m venv .venv && source .venv/bin/activate'
lab raw 'cd rebuilt && python3 -m venv .venv'
at rebuilt 'pip install -q -r ../pydata/requirements.txt'
at rebuilt 'pip freeze | wc -l'
at rebuilt 'pip check'

block lock
on 'pip freeze > requirements-lock.txt'
on 'diff <(pip freeze) <(cd ~/rebuilt && .venv/bin/pip freeze) && echo same'

# --- two environments, two kernels ----------------------------------------
fence two-environments.md py 0 | lab exec 'cat > check.py'
block old
printf 'ana@lab:~$ %s\n' 'mkdir oldpandas && cd oldpandas'
lab raw 'mkdir oldpandas'
printf 'ana@lab:~/oldpandas$ %s\n' 'python3 -m venv .venv && source .venv/bin/activate'
lab raw 'cd oldpandas && python3 -m venv .venv'
at oldpandas 'pip install -q pandas==2.2.3 ipykernel'
at oldpandas 'python ~/pydata/check.py'
on python check.py

block kernel
at oldpandas 'python -m ipykernel install --user --name oldpandas --display-name "Python (pandas 2.2)"'
on jupyter kernelspec list

# --- conda -----------------------------------------------------------------
lab raw 'rm -rf ~/miniforge3 ~/.conda Miniforge3-Linux-x86_64.sh'
lab raw 'printf "ssl_verify: /etc/ssl/certs/ca-certificates.crt\n" > ~/.condarc'
block miniforge
printf 'ana@lab:~$ %s\n' 'curl -LO https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh'
lab raw 'curl -sSLO https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh'
printf 'ana@lab:~$ %s\n' 'bash Miniforge3-Linux-x86_64.sh -b'
lab raw 'bash Miniforge3-Linux-x86_64.sh -b 2>&1 | tail -n 3'
printf 'ana@lab:~$ %s\n' 'source ~/miniforge3/bin/activate'
cdon base '~' 'conda --version'

block create-fails~
cdon base '~' 'conda create -y -q -n bikes -c conda-forge python=3.12 numpy=2.5.3 pandas=3.0.6 matplotlib=3.11.2 seaborn=0.13.2 pyarrow=26.0.0 openpyxl=3.1.5 jupyterlab=4.6.4'

block create~
cdon base '~' 'conda create -y -q -n bikes -c conda-forge python=3.12 numpy=2.5.3 pandas=3.0.6 matplotlib=3.11.2 seaborn=0.13.2 openpyxl=3.1.5 jupyterlab=4.6.4 > /dev/null && echo done'
cdon base '~' 'conda activate bikes'
cdon bikes '~' 'pip install -q pyarrow==26.0.0'
cdon bikes '~' 'conda list "^(numpy|pandas|pyarrow)$"'

block from-history
cdon bikes '~/pydata' 'conda env export --from-history'

fence conda.md yaml 0 | lab exec 'cat > environment.yml'
block yml-create
cdon base '~/pydata' 'conda env create -q -n bikes2 -f environment.yml > /dev/null && echo done'
cdon base '~/pydata' 'conda run -n bikes2 python -c "import numpy, pandas, pyarrow; print(numpy.__version__, pandas.__version__, pyarrow.__version__)"'

block sizes
cdon base '~' 'du -sh miniforge3/envs/bikes pydata/.venv'
cdon base '~' 'du -sh --exclude=envs --exclude=pkgs miniforge3'
cdon base '~' 'du -sh miniforge3/pkgs'
