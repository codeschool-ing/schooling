#!/usr/bin/env bash
# The machine every transcript and every cell output in python-data was recorded
# on, built the way lesson 1 teaches a student to build theirs.
#
# THE STUDENT NEVER SEES THIS FILE. Lesson 1 gives them the commands, section
# `the-lab`, and the program that makes the data, section `your-data`. This
# script runs those same commands, read out of the lesson's own fences, so a
# transcript is what the student's machine prints and the data is what the
# student's copy of the program writes. It adds only what a script needs and a
# person does not: the user `ana`, a stock Python, and `reset` between lessons.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the analyst of Maré Bikes, a
# bike-share scheme in Recife that does not exist: twenty stations, and every
# trip of 2025.
#
#   ~/pydata          the project lesson 1 makes
#   ~/pydata/.venv    Python 3.12 with JupyterLab, NumPy, pandas, matplotlib,
#                     seaborn, pyarrow and openpyxl, pinned as lesson 1 pins them
#   ~/pydata/*.csv    what make_data.py writes
#
#   sudo bash lab.sh up               build it (idempotent)
#   sudo bash lab.sh reset            ~/pydata as lesson 1 leaves it: the
#                                     environment kept, everything else made again
#   sudo bash lab.sh exec 'COMMAND'   run COMMAND as ana, in ~/pydata, with the
#                                     environment active, as a new terminal has it
#   sudo bash lab.sh raw 'COMMAND'    run COMMAND as ana, in ~, in a terminal where
#                                     nothing was activated
#   sudo bash lab.sh cells DIR [--write]
#                                     run lesson DIR's cells in a kernel of the
#                                     project's environment, and compare what they
#                                     printed with the lesson (or write it in)
#
# Recorded on Ubuntu 24.04 with its stock Python 3.12.3, 4 cores, 15 GB of memory.
set -euo pipefail
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON1=$HERE/lessons/le-bsym4jrs

# Ubuntu 24.04's python3 is 3.12. The machine this was recorded on had a 3.13
# installed as an alternative, so `python3` here is pointed back at the stock
# interpreter, which is the one a student's fresh machine has.
STOCK=/usr/local/lib/pydata-stock
stock_python() {
  mkdir -p $STOCK && ln -sfn /usr/bin/python3.12 $STOCK/python3
}

# What a terminal gives a person and a script does not: a width and a locale.
# The environment is activated the way lesson 1 says to, in every new terminal.
as_ana() {
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    LANG=C.UTF-8 COLUMNS=100 TZ=America/Sao_Paulo PATH=$STOCK:/usr/local/bin:/usr/bin:/bin \
    bash -c "$1"
}

# The fences of LANG in a lesson-1 file, in order, up to the first one holding
# UNTIL: the-lab.md goes on to start JupyterLab, which a build must not do.
fences() {
  python3 - "$1" "$2" "${3:-}" <<'PY'
import re, sys
text, lang, until = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2], sys.argv[3]
for body in re.findall(r"^```" + lang + r"\n(.*?)^```$", text, re.S | re.M):
    sys.stdout.write(body)
    if until and until in body:
        break
PY
}

build() {
  stock_python
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # the-lab.md: a line starting with sudo is the machine's; the rest is ana's.
  fences "$LESSON1/the-lab.md" sh "pip install" | grep '^sudo ' | sed 's/^sudo //' | while read -r line; do
    DEBIAN_FRONTEND=noninteractive bash -c "$line" >/dev/null
  done
  if [ ! -x /home/ana/pydata/.venv/bin/jupyter ]; then
    as_ana "cd && $(fences "$LESSON1/the-lab.md" sh "pip install" | grep -v '^sudo ')" >/dev/null
  fi
}

reset() {
  as_ana "cd ~/pydata && find . -mindepth 1 -maxdepth 1 ! -name .venv -exec rm -rf {} + &&
          rm -rf ~/.local/share/jupyter/runtime"
  fences "$LESSON1/your-data.md" py | as_ana "cat > ~/pydata/make_data.py"
  as_ana "cd ~/pydata && source .venv/bin/activate && python make_data.py" >/dev/null
}

case "${1:-}" in
  up)
    build; reset ;;
  reset)
    reset ;;
  exec)
    as_ana "cd ~/pydata && source .venv/bin/activate && $2" ;;
  raw)
    as_ana "cd ~ && $2" ;;
  cells)
    dir=$(cd "$2" && pwd); shift 2
    out=$(mktemp -d /tmp/pydata-cells.XXXX); chmod 777 "$out"
    as_ana "cd ~/pydata && .venv/bin/python '$HERE/lab/cells.py' run '$dir' '$out/result.json'"
    python3 "$HERE/lab/cells.py" apply "$@" "$dir" "$out/result.json" ;;
  *)
    echo "usage: lab.sh up | reset | exec 'COMMAND' | raw 'COMMAND' | cells DIR [--write]" >&2; exit 2 ;;
esac
