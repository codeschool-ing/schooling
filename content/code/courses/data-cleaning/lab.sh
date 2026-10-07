#!/usr/bin/env bash
# The machine every transcript in data-cleaning was recorded on, built the way
# lesson 1 teaches a student to build theirs.
#
# THE STUDENT NEVER SEES THIS FILE. Lesson 1 gives them the commands, section
# `the-lab`, and the generator and the loading script in full, section
# `your-data`. This script runs those same commands, in that order, so that a
# transcript is what the student's own machine prints; it adds only what a
# script needs and a person does not: the user `ana`, a way to start
# PostgreSQL in a machine with no systemd, and `reset` between lessons. The
# generator and the loader are NOT kept here: they are read out of the lesson's
# own fences, so the program the course ran is the program the student types.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the data analyst of Quitanda Verde, an
# organic grocer that does not exist: five shops, in São Paulo, Campinas, Rio
# de Janeiro, Belo Horizonte and Curitiba, and a website and an app that
# deliver. In the first week of January 2026 she is handed what the company's
# systems export, and asked whether 2025 can be trusted.
#
#   ~/clean-data   the generator and the loader as lesson 1 shows them, and
#                  what the generator writes: raw/ is what the systems
#                  exported, ref/ is reference data from outside the company,
#                  truth/ says where every planted defect is
#   ~/clean        the working directory: raw/ (read-only) and ref/ copied in
#   ~/venv         Python 3.12 with pandas, RapidFuzz and Matplotlib, pinned
#   PostgreSQL 16  Ubuntu's own cluster, database `quitanda` owned by ana,
#                  schema `raw` with every file loaded as text
#   R 4.3          with dplyr, tidyr and readr, from Ubuntu's own packages
#
# NOT REACHABLE, AND THEREFORE NOT RUN: Microsoft Excel and Power Query.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           lesson 1's "start everything again": ~/clean and
#                                    `quitanda` made afresh, the files loaded
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/clean, in the
#                                    shell lesson 1's lines in ~/.bashrc make
#   sudo bash lab.sh stop | start    the server, for lesson 1's failures; start
#                                    is the command the lesson gives
#
# Recorded on Ubuntu 24.04 with Python 3.12, PostgreSQL 16 and R 4.3.3, 4 cores.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The server started
# here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON1=$HERE/lessons/le-kzw67m5d
PACKAGES="postgresql python3-venv r-base-core r-cran-dplyr r-cran-tidyr r-cran-readr"
PYLIBS="pandas==3.0.6 numpy==2.5.3 rapidfuzz==3.14.6 matplotlib==3.11.2"

# Ubuntu 24.04's python3 is 3.12. The machine this was recorded on had a 3.13
# installed as an alternative, so `python3` here is pointed back at the stock
# interpreter, which is the one a student's fresh machine has.
STOCK=/usr/local/lib/clean-stock
stock_python() {
  mkdir -p $STOCK && ln -sfn /usr/bin/python3.12 $STOCK/python3
}

# What a terminal gives a person and a script does not: a width, and a locale.
# Everything else comes from the lines lesson 1 adds to ~/.bashrc.
as_ana() {
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    LANG=C.UTF-8 COLUMNS=100 PATH=$STOCK:/usr/local/bin:/usr/bin:/bin \
    bash -c 'eval "$(sed -n "/^# data-cleaning$/,\$p" ~/.bashrc)"; '"$1"
}

# The one fence of LANG in your-data.md, which is the whole file a student saves.
fence() {
  python3 - "$LESSON1/your-data.md" "$1" <<'PY2'
import re, sys
text, lang = open(sys.argv[1], encoding="utf-8").read(), sys.argv[2]
found = re.findall(r"^```" + lang + r"\n(.*?)^```$", text, re.S | re.M)
if len(found) != 1:
    sys.exit(f"your-data.md has {len(found)} {lang} fences, and lab.sh needs exactly one")
sys.stdout.write(found[0])
PY2
}

cluster_up() {
  # In a virtual machine apt starts it and systemd keeps it running.
  pg_lsclusters -h | grep -q ' online ' || pg_ctlcluster 16 main start
}

build() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q $PACKAGES >/dev/null
  cluster_up
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'ana'" | grep -q 1 ||
    runuser -u postgres -- createuser --createdb ana
  stock_python
  as_ana "cd && { [ -x venv/bin/python ] || python3 -m venv venv; } && venv/bin/pip install -q $PYLIBS"
  grep -q '^# data-cleaning$' /home/ana/.bashrc || cat >> /home/ana/.bashrc <<'EOF'
# data-cleaning
export TZ=America/Sao_Paulo
export PGDATABASE=quitanda
source ~/venv/bin/activate
EOF
  runuser -u ana -- mkdir -p /home/ana/clean-data
  fence python > /home/ana/clean-data/generate.py
  fence sql > /home/ana/clean-data/raw.sql
  chown ana:ana /home/ana/clean-data/generate.py /home/ana/clean-data/raw.sql
  as_ana "cd ~/clean-data && rm -rf raw ref truth && python3 generate.py ."
}

reset() {
  cluster_up
  as_ana "chmod -R u+w ~/clean 2>/dev/null; rm -rf ~/clean
    dropdb --if-exists quitanda
    createdb --template=template0 --locale=C.UTF-8 quitanda
    psql -q -c \"ALTER DATABASE quitanda SET datestyle = 'ISO, DMY'\" \
            -c \"ALTER DATABASE quitanda SET timezone = 'America/Sao_Paulo'\"
    mkdir ~/clean && cp -r ~/clean-data/raw ~/clean-data/ref ~/clean/
    chmod -R a-w ~/clean/raw
    cd ~/clean && psql -q -f ~/clean-data/raw.sql"
}

case "${1:-}" in
  up)
    build; reset ;;
  reset)
    reset ;;
  exec)
    as_ana "cd ~/clean && $2" ;;
  stop)
    pg_ctlcluster 16 main stop ;;
  start)
    service postgresql start ;;
  *)
    echo "usage: lab.sh up | reset | exec 'COMMAND' | stop | start" >&2; exit 2 ;;
esac
