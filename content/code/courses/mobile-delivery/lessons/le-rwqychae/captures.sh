#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of mobile-delivery, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. inventory.json and
# privacy.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "broken" makes broken.json, a copy of the inventory with the crash
#     reports' purposes removed, by a node one-liner the lesson does not print.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block privacy
put the-inventory.md inventory.json $P/inventory.json
put the-inventory.md privacy.ts $P/privacy.ts
run $P 'node privacy.ts'

block broken
LAB as "cd ~/planner && node -e 'const fs=require(\"fs\");const i=JSON.parse(fs.readFileSync(\"inventory.json\"));delete i.data[2].purposes;fs.writeFileSync(\"broken.json\",JSON.stringify(i))'"
run $P 'node privacy.ts broken.json; echo "exit status $?"'
LAB as 'rm -f ~/planner/broken.json'
