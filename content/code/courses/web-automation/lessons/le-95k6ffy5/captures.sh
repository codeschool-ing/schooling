#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `jsdom-in-practice` shows
# the new package.json and simulated/home.mjs and shop.mjs, `htmlunit` shows
# htmlunit/pom.xml and htmlunit/Shop.java, `what-they-miss` and
# `when-they-fit` show the rest of simulated/; ../../lab.sh builds the project
# from those very blocks. What is STAGED rather than typed, beyond what
# ../../lab.sh's header lists for every lesson:
#   - the shop. It is started in the background, as the student starts it with
#     `npm start` in another terminal.
#   - in "home-bare", the first simulated/home.mjs of `jsdom-in-practice`,
#     which the section later replaces, put back for one run.
#   - Zombie. It is installed in ~/zombie-try, outside the project, as the
#     section says, and that folder is deleted at the end; visit.js is written
#     there from the block in zombie.md that starts with its first comment.
#   - Maven. It needs the network, so it runs as root (like npm) in ana's
#     folder, printed as ana. repo1.maven.org answered 404 with a Retry-After
#     of some seventeen hours on the day of recording, so Maven used Google's
#     mirror of Maven Central through a settings file passed with -s, and its
#     own repository in /tmp; the section says a mirror was used. Java's
#     "Picked up JAVA_TOOL_OPTIONS" line, which this sandbox's proxy settings
#     cause, is dropped from Maven's output.
#   - colour codes. Playwright's error message in "hidden" carries ANSI
#     escapes for its dim call log; exactly ESC[...m is stripped with sed.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0, Chromium 141.0.7390.37, jsdom 30.1.2, Zombie 6.1.4,
# HtmlUnit 5.6.0 and OpenJDK 21.0.12.1, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 18 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolour() { sed 's/\x1b\[[0-9;]*m//g'; }

# ---- zombie ------------------------------------------------------------------
block zombie-time
printf 'ana@laptop:~/quitanda$ npm view zombie time | tail -6\n'
npm_in "$P" view zombie time 2>&1 | tail -6
block zombie-deps
run_npm view zombie version dependencies.jsdom dependencies.request
run_npm view request deprecated

Z=$ANA_HOME/zombie-try
rm -rf "$Z"; mkdir -p "$Z"; chown ana:ana "$Z"
block zombie-install
printf 'ana@laptop:~/zombie-try$ npm install zombie@6.1.4\n'
npm_in "$Z" install zombie@6.1.4 2>&1
python3 - "$HERE/zombie.md" "$Z/visit.js" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r"```javascript\n(// Zombie against the shop:.*?)\n```", text, re.S)
open(sys.argv[2], "w").write(m.group(1) + "\n")
PY
chown ana:ana "$Z/visit.js"

start_app
block zombie-visit
run_in "$Z" 'node visit.js'
block zombie-debug
run_in "$Z" 'DEBUG=zombie node visit.js'
rm -rf "$Z"

# ---- htmlunit ----------------------------------------------------------------
block java-version
run 'java -version'
block mvn-deps
M=/tmp/l18-maven; mkdir -p "$M"
cat > "$M/settings.xml" <<'XML'
<settings><mirrors><mirror><id>gcs</id><mirrorOf>central</mirrorOf><url>https://maven-central.storage-download.googleapis.com/maven2</url></mirror></mirrors></settings>
XML
printf 'ana@laptop:~/quitanda/htmlunit$ mvn -q dependency:copy-dependencies -DoutputDirectory=lib\n'
(cd "$P/htmlunit" && mvn -q -s "$M/settings.xml" -Dmaven.repo.local="$M/repo" \
  dependency:copy-dependencies -DoutputDirectory=lib 2>&1 | grep -v '^Picked up JAVA_TOOL_OPTIONS')
chown -R ana:ana "$P/htmlunit"
run_in "$P/htmlunit" 'ls lib'
block htmlunit-lines
run_in "$P/htmlunit" "java -cp 'lib/*' Shop.java 2>&1 | wc -l"
block htmlunit-run
run_in "$P/htmlunit" "java -cp 'lib/*' Shop.java 2>&1 | grep -E 'cards|ScriptException'"

# ---- jsdom -------------------------------------------------------------------
block jest-env
run_npm view jest-environment-jsdom version dependencies.jsdom
block npm-install
rm -rf node_modules package-lock.json
run_npm install
block jsdom-engines
run_npm view jsdom@30.1.2 engines

block home-bare
cp simulated/home.mjs /tmp/l18-home.mjs
bash "$HERE/../../lab.sh" fence "$HERE/jsdom-in-practice.md" simulated/home.mjs > simulated/home.mjs
run 'node simulated/home.mjs'
cp /tmp/l18-home.mjs simulated/home.mjs; chown ana:ana simulated/home.mjs
block home
run 'node simulated/home.mjs'

# ---- what-they-miss / when-they-fit -----------------------------------------
block missing
run 'node simulated/missing.mjs'
block hidden
run 'node simulated/hidden.mjs' | nocolour
block timing
run 'node simulated/timing.mjs'
block timing-again
run 'node simulated/timing.mjs'
block ssr-test
run 'node --test --test-reporter=tap simulated/ssr.test.mjs'
stop_app

block project-tests
run 'npx playwright test tests/smoke.spec.js'
