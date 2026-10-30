#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of mobile-offline, as a script that
# produces them. The output is not committed: lab/fill.py pastes each block
# into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine, and starts from no ~/planner. package.json,
# check.ts, data.ts, show.ts and sandbox.ts are taken from the lesson by
# lab/extract.py, so the program each transcript ran is the one it prints.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "typeless" runs check.ts with "type": "module" removed from a copy of
#     package.json, and puts the file back.
#   - "elsewhere" copies check.ts into ~/elsewhere, which has no node_modules.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'rm -rf ~/planner ~/elsewhere'

block versions
run /home/ana 'node --version'
run /home/ana 'npm --version'

block project
LAB as 'mkdir -p ~/planner'
put your-computer.md package.json $P/package.json
run $P 'npm install -E better-sqlite3@13.0.3'
run $P 'cat package.json'

block check
put your-computer.md check.ts $P/check.ts
run $P 'node check.ts'

block show
put the-planner.md data.ts $P/data.ts
put the-planner.md show.ts $P/show.ts
run $P 'node show.ts 2026-10-19'
run $P 'node show.ts 2026-10-26'

block backup
put what-backup-takes.md sandbox.ts $P/sandbox.ts
run $P 'node sandbox.ts android'
run $P 'node sandbox.ts android files/attachments/'
run $P 'node sandbox.ts ios'

block typeless
LAB as 'cd ~/planner && cp package.json package.json.keep && node -e "const p=require(\"./package.json\");delete p.type;require(\"fs\").writeFileSync(\"package.json\",JSON.stringify(p,null,2)+\"\\n\")"'
run $P 'node check.ts'
LAB as 'cd ~/planner && mv package.json.keep package.json'

block elsewhere
LAB as 'mkdir -p ~/elsewhere && cp ~/planner/check.ts ~/elsewhere/'
run /home/ana/elsewhere 'node check.ts 2>&1 | head -n 5'
LAB as 'rm -rf ~/elsewhere ~/planner/sandbox-android ~/planner/sandbox-ios'
