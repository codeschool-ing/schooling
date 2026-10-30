#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: ~/.cbtrc is the file the-model.md introduces,
# clicks.py is the schooling-example of row-keys.md and tablets.py the one of
# hotspots.md, all read out of the lesson as they stand. The Bigtable emulator
# is started with the command of the-model.md's first fence, as the student
# starts it in a terminal of its own, and it is empty when this begins.
#
# STAGED: nothing beyond what lab.sh stages for every lesson. The emulator runs
# in the background here rather than in a second terminal.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$HERE"

[ "$(fence "$L/the-model.md" 1 | tail -1)" = "$(emu_cmd bigtable)" ] \
  || { echo "the-model.md's first fence no longer starts the emulator the way emu_start does"; exit 1; }
emu_start bigtable || exit 1

# ---- the-model ---------------------------------------------------------------
block model-flags
run 'cbt -project planner-dev -instance quitanda ls'
file_fence "$L/the-model.md" '~/.cbtrc' > ~/.cbtrc
block model-table
run 'cbt createtable customers families=p,o'
run 'cbt ls customers'
run 'cbt ls'
block model-rows
run 'cbt set customers c-17 p:name=Ana p:district=Lapa'
run 'cbt set customers c-18 p:name=Bruno o:o-10004=4290 o:o-10005=1380'
run 'cbt read customers'
run 'cbt set customers c-18 x:note=vip'

# ---- versions ----------------------------------------------------------------
block versions-four
run 'cbt deleterow customers c-17'
run 'cbt set customers c-17 p:name=Ana@1788000000000000 p:district=Lapa@1788000000000000'
run 'cbt set customers c-17 p:district=Mooca@1790000000000000'
run 'cbt set customers c-17 p:district=Pinheiros@1792000000000000'
run 'cbt set customers c-17 p:district=Santana@1792100000000000'
run 'cbt lookup customers c-17'
run 'cbt lookup customers c-17 cells-per-column=1'
block versions-millis
run 'cbt set customers c-18 p:district=Lapa@1788000000000'
run 'cbt lookup customers c-18 columns=p:district'
block versions-policy
run 'cbt setgcpolicy customers p maxage=30d or maxversions=2'
run 'cbt ls customers'
run 'cbt lookup customers c-17'
run 'sleep 10 && cbt lookup customers c-17'
run 'cbt lookup customers c-18'

# ---- row-keys ----------------------------------------------------------------
example "$L/row-keys.md" clicks.py clicks.py
block rk-table
run 'cbt createtable clicks families=ev:maxversions=1'
run 'cbt ls clicks'
block rk-load
run 'python3 clicks.py load'
block rk-keys
run "cbt read clicks columns=ev:screen | grep '^\"'"
block rk-reads
run 'cbt read clicks prefix=c-17# count=2'
run 'python3 clicks.py key c-17 18:46'
run 'cbt read clicks start=$(python3 clicks.py key c-17 18:46) end=$(python3 clicks.py key c-17 18:40) columns=ev:screen'
block rk-prefix
run 'python3 clicks.py load 2000'
run 'cbt count clicks'
run "cbt read clicks prefix=c-17 columns=ev:screen | grep -c '^\"'"
run "cbt read clicks prefix=c-17# columns=ev:screen | grep -c '^\"'"
block rk-stats
run 'cbt read clicks prefix=c-17# include-stats=full | tail -7'
run "cbt read clicks regex='c-17#.*' include-stats=full | tail -7"
run 'cbt read clicks prefix=c-17# reversed=true count=1'

# ---- hotspots ----------------------------------------------------------------
example "$L/hotspots.md" tablets.py tablets.py
block hot-model
run 'python3 tablets.py'

# ---- nodes-and-bill ----------------------------------------------------------
block bill-emu
run 'cbt listinstances'
run "cbt createinstance quitanda-prod 'Quitanda prod' quitanda-c1 southamerica-east1-a 3 SSD"
block bill-price
run "python3 -c 'node = 0.98 * 730; print(round(node, 2), round(3 * node, 2), round(6 * node, 2))'"
run "python3 -c 'print(round(3 * 0.784 * 730, 2), round(3 * 0.588 * 730, 2))'"
run "python3 -c 'print(2048 * 0.26, round(2048 * 0.039, 2), 8 * 90, round(8 * 90 * 0.26, 2))'"
block end
emu_stop bigtable
