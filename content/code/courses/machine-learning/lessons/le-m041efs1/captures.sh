#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash captures.sh > /tmp/l1.txt
#   python3 ../../lab/paste.py --check . /tmp/l1.txt
#
# It starts from NOTHING: ana and an empty ~/ml. requirements.txt,
# make_data.py and the lines for ~/.bashrc are read out of the-lab.md and
# your-data.md, so what ran is what the lesson prints. pip downloads from the
# Python Package Index, so this needs the network once. The failures are
# staged in a scratch folder, ~/broken, which is removed at the end.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, 4 cores, TZ=America/Sao_Paulo,
# on 2026-10-10.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab down >/dev/null 2>&1
lab bare
save "$HERE/the-lab.md" requirements.txt

block install
sess <<'CMDS'
python3 --version
python3 -m venv .venv
source .venv/bin/activate
pip install --quiet -r requirements.txt
CMDS

lab exec "$(python3 "$LAB_DIR/lab/extract.py" "$HERE/the-lab.md" --with '# machine-learning')"

block versions
sess <<'CMDS'
which python
python --version
python -c "import sklearn, pandas, numpy; print(sklearn.__version__, pandas.__version__, numpy.__version__)"
CMDS

block disk
on 'du -sh .venv'

save "$HERE/your-data.md" make_data.py
block generate
on 'python make_data.py'

block checksums
on 'sha256sum data/*.csv'

block head
on 'head -3 data/churn.csv'

block fail-module
sess <<'CMDS'
deactivate
python3 make_data.py
CMDS

block fail-managed
sess <<'CMDS'
deactivate
python3 -m pip install -r requirements.txt
CMDS

block fail-folder
sess <<'CMDS'
cd ~
python make_data.py
CMDS

block fail-typo
quiet 'mkdir -p ~/broken && sed s/scikit-learn/scikit-lean/ requirements.txt > ~/broken/requirements.txt'
sess <<'CMDS'
cd ~/broken
pip install --quiet -r requirements.txt
CMDS
quiet 'rm -rf ~/broken'

save "$HERE/prediction-and-decision.md" frame.py
block frame
on 'python frame.py'
