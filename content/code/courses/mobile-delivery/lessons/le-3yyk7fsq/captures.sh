#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of mobile-delivery, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine, which has R8 8.13.25 as ~/android/r8.jar, and
# lesson 1's ~/planner. week.ts, symbolicate.ts, Week.java and rules.pro are
# taken from the lesson by lab/extract.py. esbuild and source-map are installed
# with the npm line the lesson prints, quietly.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The R8 mapping identifier in the shrunk trace is a hash of the mapping,
#     and changes if R8 or the program changes; the prose quotes none of it.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
J=/home/ana/planner/jvm
LAB as 'rm -rf ~/planner/jvm ~/planner/dist'
quiet $P 'npm install -E esbuild@0.28.2 source-map@0.8.0'

block bundle
put a-minified-javascript-trace.md week.ts $P/week.ts
run $P 'npx esbuild week.ts --bundle --minify --sourcemap --platform=node --format=esm --log-level=warning --outfile=dist/bundle.js'
run $P 'ls dist; cat dist/bundle.js'
run $P 'node dist/bundle.js 2> trace.txt; cat trace.txt'

block symbolicated
put a-minified-javascript-trace.md symbolicate.ts $P/symbolicate.ts
run $P 'node symbolicate.ts dist/bundle.js.map < trace.txt'

block r8
put r8-and-retrace.md Week.java $J/src/planner/Week.java
put r8-and-retrace.md rules.pro $J/rules.pro
run $J 'javac -d classes src/planner/Week.java && jar --create --file week.jar -C classes .'
run $J 'java -cp ~/android/r8.jar com.android.tools.r8.R8 --release --classfile --lib /usr/lib/jvm/java-21-openjdk-amd64 --pg-conf rules.pro --pg-map-output mapping.txt --output shrunk.jar week.jar'
run $J 'ls -l week.jar shrunk.jar; unzip -Z1 shrunk.jar'
run $J 'java -cp shrunk.jar planner.Week 2> trace.txt; cat trace.txt'

block retrace
run $J 'java -cp ~/android/r8.jar com.android.tools.r8.retrace.Retrace mapping.txt trace.txt'
run $J 'java -cp week.jar planner.Week 2>&1 | tail -n 3'
