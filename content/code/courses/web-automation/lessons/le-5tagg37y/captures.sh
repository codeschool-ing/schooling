#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `first-test` shows
# package.json again, with selenium-webdriver beside Playwright, and every file
# under selenium/ whole; ../../lab.sh builds the project from those blocks.
# What is STAGED rather than done the student's way, beyond what ../../lab.sh's
# header lists for every lesson:
#   - the driver and the browser. The student's Selenium Manager downloads a
#     chromedriver matching their Chrome into ~/.cache/selenium. Here ana has
#     no network, so chromedriver 141.0.7390.122 (from the chromedriver-py
#     wheel on PyPI) sits in ~/bin with `google-chrome` there linked to
#     Playwright's Chromium 141.0.7390.37, and Selenium Manager finds both on
#     the PATH without downloading. Its two WARN lines in "manager" and in the
#     grid's log are this machine failing to reach the internet.
#   - in "mismatch" and "mismatch142", chromedriver 139.0.7258.154 and
#     142.0.7444.175, from the chromedriver-py wheels of those versions, are
#     put first on ana's PATH for one command each; the command shown is the
#     one she typed, the PATH is the staging. In "warn140", chromedriver
#     140.0.7339.207 the same way, started on port 9516, one session opened and
#     closed with curl, and only its WARNING lines kept.
#   - in "fail-run", the expected count in selenium/shop.test.js changed from
#     '1' to '2' with sed for one run and put back.
#   - in "grid-start", the Selenium server jar. The student downloads
#     selenium-server-4.51.0.jar from the Selenium project's GitHub releases;
#     ana cannot, so the same file, fetched from
#     https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.51.0/
#     (sha256 f4ddbb992fd99c4152934b832c5fe5502a5ca207a1d1cb96af8e5068955c5037),
#     is copied into her home. Java is Ubuntu's OpenJDK 21.
#   - "the-protocol" blocks: the session id and element id ana pastes into
#     each curl are the ones the previous answer printed; the script reads them
#     out of that answer. The pauses between commands are a person typing.
#   - Firefox and geckodriver are not on this machine; nothing here runs them.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0, selenium-webdriver 4.51.0, Selenium Grid 4.51.0, OpenJDK
# 21.0.12, chromedriver 141.0.7390.122 and Chromium 141.0.7390.37,
# TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 8 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
JAR=selenium-server-4.51.0.jar
old_driver() {   # old_driver VERSION DIR: a chromedriver of that version from PyPI
  [ -x "$2/chromedriver" ] && return 0
  local tmp; tmp=$(mktemp -d)
  pip download --quiet --no-deps -d "$tmp" "chromedriver-py==$1" &&
    python3 -m zipfile -e "$tmp"/chromedriver_py-*.whl "$tmp/x" &&
    install -D -m 755 "$tmp/x/chromedriver_py/chromedriver_linux64" "$2/chromedriver"
  rm -rf -- "$tmp"; chown -R ana:ana "$2"
}
OLD=$ANA_HOME/chromedriver-139; old_driver 139.0.7258.154 "$OLD"
OLD140=$ANA_HOME/chromedriver-140; old_driver 140.0.7339.207 "$OLD140"
OLD142=$ANA_HOME/chromedriver-142; old_driver 142.0.7444.175 "$OLD142"
if [ ! -f "$ANA_HOME/$JAR" ]; then
  curl -sSL -o "$ANA_HOME/$JAR" "https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.51.0/$JAR"
  chown ana:ana "$ANA_HOME/$JAR"
fi

block npm-install
rm -rf node_modules package-lock.json
run_npm install

# ---- the-protocol -------------------------------------------------------------
start_app
block chromedriver
printf 'ana@laptop:~/quitanda$ chromedriver --port=9515\n'
bg_ana "exec chromedriver --port=9515" /tmp/l8-cd.out
sleep 1.5
cat /tmp/l8-cd.out
block status
run 'curl -s http://localhost:9515/status'; echo
block session
run "curl -s -X POST http://localhost:9515/session -H 'Content-Type: application/json' -d '{\"capabilities\":{\"alwaysMatch\":{\"browserName\":\"chrome\",\"goog:chromeOptions\":{\"args\":[\"--headless=new\"]}}}}'" | tee /tmp/l8-sess.out; echo
S=$(tail -1 /tmp/l8-sess.out | python3 -c 'import json,sys;print(json.load(sys.stdin)["value"]["sessionId"])')
block navigate
run "curl -s -X POST http://localhost:9515/session/$S/url -H 'Content-Type: application/json' -d '{\"url\":\"http://localhost:3000/\"}'"; echo
sleep 1
block find
run "curl -s -X POST http://localhost:9515/session/$S/element -H 'Content-Type: application/json' -d '{\"using\":\"css selector\",\"value\":\"[data-testid=product-banana] h2\"}'" | tee /tmp/l8-el.out; echo
E=$(tail -1 /tmp/l8-el.out | python3 -c 'import json,sys;print(list(json.load(sys.stdin)["value"].values())[0])')
block text
run "curl -s http://localhost:9515/session/$S/element/$E/text"; echo
block delete
run "curl -s -X DELETE http://localhost:9515/session/$S"; echo
stop_bg

# ---- drivers -------------------------------------------------------------------
block manager
run 'node_modules/selenium-webdriver/bin/linux-x86_64/selenium-manager --browser chrome --debug'

block warn140
bg_ana "exec $OLD140/chromedriver --port=9516" /tmp/l8-140.out
sleep 1
as_ana "curl -s -X POST http://localhost:9516/session -H 'Content-Type: application/json' -d '{\"capabilities\":{\"alwaysMatch\":{\"browserName\":\"chrome\",\"goog:chromeOptions\":{\"args\":[\"--headless=new\"]}}}}'" >/tmp/l8-140.json
S=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["value"]["sessionId"])' /tmp/l8-140.json)
as_ana "curl -s -X DELETE http://localhost:9516/session/$S" >/dev/null
stop_bg
grep -E 'WARNING|SEVERE' /tmp/l8-140.out | grep -v CreatePlatformSocket

start_app
block mismatch
printf 'ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js\n'
as_ana "cd $P && PATH=$OLD:\$PATH node --test --test-reporter=spec selenium/shop.test.js" 2>&1
block mismatch142
printf 'ana@laptop:~/quitanda$ node --test --test-reporter=spec selenium/shop.test.js\n'
as_ana "cd $P && PATH=$OLD142:\$PATH node --test --test-reporter=spec selenium/shop.test.js" 2>&1

# ---- first-test ----------------------------------------------------------------
block first-run
run 'node --test --test-reporter=spec selenium/shop.test.js'

block fail-run
cp selenium/shop.test.js /tmp/l8-shop.test.js
sed -i "s/until.elementTextIs(count, '1')/until.elementTextIs(count, '2')/" selenium/shop.test.js
run 'node --test --test-reporter=spec selenium/shop.test.js'
cp /tmp/l8-shop.test.js selenium/shop.test.js; chown ana:ana selenium/shop.test.js

# ---- waits-in-selenium ---------------------------------------------------------
block waits
run 'node selenium/waits.mjs'
stop_app

# ---- the-grid ------------------------------------------------------------------
block java
run_in "$ANA_HOME" 'java -version'
block grid-start
printf 'ana@laptop:~$ java -jar %s standalone\n' "$JAR"
bg_ana "cd $ANA_HOME && exec java -jar $JAR standalone" /tmp/l8-grid.out
for _ in $(seq 120); do grep -q "Started Selenium" /tmp/l8-grid.out && break; sleep 0.5; done
cat /tmp/l8-grid.out
GRID_LINES=$(wc -l < /tmp/l8-grid.out)
bg_ana "cd $P && exec node app/server.js" /dev/null
wait_app
block grid-run
run 'SELENIUM_REMOTE_URL=http://localhost:4444 node --test --test-reporter=spec selenium/shop.test.js'
sleep 1
block grid-log
tail -n +$((GRID_LINES + 1)) /tmp/l8-grid.out
stop_bg
