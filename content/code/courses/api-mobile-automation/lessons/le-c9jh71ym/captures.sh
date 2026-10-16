#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. Gestures, permissions and app states all happen
# on a device, and this sandbox has none (lesson 14): Tickets was never built,
# no emulator can start, and adb has nothing to talk to. So the two Appium test
# files and the Espresso test class the lesson writes were not run; the Appium
# ones are checked for syntax by Node and the Espresso one not at all, since it
# needs androidx (lesson 16). What is recorded, all of it real:
#   - gestures sent through the real Appium server to Appium's fake driver
#     (lesson 15), which keeps a log of the W3C actions it receives, and the
#     server's own log of those requests; and the refusal the fake driver gives
#     a command that belongs to the UiAutomator2 driver;
#   - where Tickets asks for its permission and where it keeps its state, read
#     from its source with grep;
#   - Appium refusing an insecure feature named without its driver, and
#     starting with the one the lesson's process-death test needs;
#   - the app's own sources still compiling (`lab.sh appcheck`), since the
#     lesson adds nothing to src/main.
# What is STAGED rather than typed:
#   - Appium, WebdriverIO and the two drivers. Lesson 15 installs them with
#     npm, but ../../lab.sh rebuilds the project from the lessons' blocks and
#     the package.json it writes is lesson 6's, because npm, not a block,
#     wrote lesson 15's entries. So lesson 15's three install commands are
#     repeated here quietly, with the same versions;
#   - the server, started in the background where the student has it running
#     in a terminal of its own since lesson 15; lines quoted from it are read
#     from its log;
#   - adb's server, which the UiAutomator2 driver may start, is stopped at the
#     end, as lesson 14's captures do.
# The session id and the element ids differ on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, Appium 3.8.0,
# appium-uiautomator2-driver 8.7.0, @appium/fake-driver 6.2.4, WebdriverIO
# 9.32.0 and platform-tools 36.0.0, TZ=America/Sao_Paulo, as user ana. See
# ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 21 /home/ana/boxoffice
lab_appcheck /home/ana/boxoffice >&2 || { echo "captures: the app does not compile" >&2; exit 1; }
here /home/ana/boxoffice

# start NAME CMD URL: like serve, for a server that never prints "listening";
# it waits until URL answers instead, for up to two minutes.
start() {
  as_ana "$2 > /tmp/lab-$1.log 2>&1 < /dev/null 9>&- & echo \$! > /tmp/lab-$1.pid"
  for _ in $(seq 1200); do
    as_ana "curl -s -o /dev/null $3" && return 0
    sleep 0.1
  done
  echo "lab: $1 did not answer at $3" >&2; cat "/tmp/lab-$1.log" >&2; return 1
}
# halt_tree NAME: halt, and every process below it first, by pid.
kids() { local p; for p in $(pgrep -P "$1"); do kids "$p"; echo "$p"; done; }
halt_tree() {
  [ -f "/tmp/lab-$1.pid" ] || return 0
  local top; top=$(cat "/tmp/lab-$1.pid")
  kill $(kids "$top") "$top" 2>/dev/null
  rm -f "/tmp/lab-$1.pid"
  sleep 0.5
}
trap 'halt_tree appium' EXIT

quiet 'adb kill-server'
quiet 'npm install --save-dev --save-exact appium@3.8.0 webdriverio@9.32.0' \
  || { echo "captures: npm install failed" >&2; exit 1; }
quiet 'npx appium driver install uiautomator2@8.7.0'
quiet 'npx appium driver install --source=npm @appium/fake-driver@6.2.4'
for f in appium/fake-gestures.mjs appium/reminder.test.mjs appium/states.test.mjs \
         appium/screens/show.mjs appium/screens/permission.mjs; do
  as_ana "node --check $f" >&2 || { echo "captures: $f does not parse" >&2; exit 1; }
done

start appium 'npx appium --address 127.0.0.1' localhost:4723/status

# ---- gestures ----------------------------------------------------------------
LINES_BEFORE=$(wc -l < /tmp/lab-appium.log)
block gestures
run 'node appium/fake-gestures.mjs'

block actions-log
strip < /tmp/lab-appium.log | tail -n +"$((LINES_BEFORE + 1))" \
  | grep -E '\[HTTP\] --> (POST|DELETE) .*/actions' | sed -E -e 's/ \{.*//' -e 's/ +$//'

# ---- permissions -------------------------------------------------------------
block permission-code
run "grep -n 'POST_NOTIFICATIONS' tickets/app/src/main/AndroidManifest.xml"
run "grep -n 'SDK_INT\\|POST_NOTIFICATIONS\\|granted' tickets/app/src/main/java/example/tickets/ShowActivity.kt"

# ---- app-states --------------------------------------------------------------
block state-code
run "grep -n 'getSharedPreferences\\|getStringExtra\\|getIntExtra\\|var baseUrl\\|visibility =' tickets/app/src/main/java/example/tickets/*.kt"

halt_tree appium
block insecure-refused
run "npx appium --address 127.0.0.1 --allow-insecure adb_shell 2>&1 | grep '^Error'"

block insecure
prompt; echo 'npx appium --address 127.0.0.1 --allow-insecure uiautomator2:adb_shell'
start appium 'npx appium --address 127.0.0.1 --allow-insecure uiautomator2:adb_shell' localhost:4723/status
strip < /tmp/lab-appium.log | grep -E -A1 'Non-default server args'
strip < /tmp/lab-appium.log | grep -E 'listener started'

halt_tree appium
quiet 'adb kill-server'
