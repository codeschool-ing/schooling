#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. Everything Appium does without a device ran:
# installing Appium, WebdriverIO and two drivers from npm into the project,
# the UiAutomator2 driver's doctor reading the SDK, the server itself, and a
# whole session against Appium's own fake driver (@appium/fake-driver, the
# driver Appium's developers test Appium with), first by hand with curl and
# then through WebdriverIO. The fake driver loads appium/tickets-model.xml, a
# model of Tickets's list screen the lesson shows whole, and the lesson says
# that it is a stand-in. What could not run is a session against Tickets: the
# app was never built here (lesson 14) and no emulator can start. The test
# the lesson writes for Tickets WAS run, against no device, and the block
# `no-device` is the failure it gives, in the TAP report; the page-object version of section 07
# was not run at all.
#
# What is STAGED rather than typed:
#   - JAVA_HOME. Section 03 has the student add it to ~/.bashrc; here it is
#     put in the environment of every command after that point;
#   - the server, started in the background where the lesson starts it in a
#     terminal of its own; the lines shown under each start are read from its
#     log, and so are the lines of block `wait-log`. It is restarted after the
#     fake driver is installed, as the lesson says to with Ctrl-C;
#   - the session id, which the student copies from the answer into SESSION;
#     here it is read from that same answer;
#   - adb's server, which the UiAutomator2 driver starts while it looks for a
#     device, is stopped at the end, as lesson 14's captures do.
# The session id and the timestamps differ on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4, Appium
# 3.8.0, appium-uiautomator2-driver 8.7.0, @appium/fake-driver 6.2.4,
# WebdriverIO 9.32.0, OpenJDK 21 and platform-tools 36.0.0,
# TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 15 /home/ana/boxoffice
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
# the server's start-up lines, up to the one that says it has no plugins
startup() { strip < /tmp/lab-appium.log | sed -n '1,/No plugins have been installed/p'; }

J="-H 'content-type: application/json'"
quiet 'adb kill-server'

# ---- installing --------------------------------------------------------------
block install
run 'npm install --save-dev --save-exact appium@3.8.0 webdriverio@9.32.0'

block version
run 'npx appium --version'

block driver
run 'npx appium driver install uiautomator2@8.7.0 2>&1 | tail -3'

# The doctor marks every check with a tick or a cross the course's font has no
# glyph for, so the lesson quotes its lines in a table, from this full run, and
# prints the summary lines a grep keeps.
block doctor-full
run 'npx appium driver doctor uiautomator2'

block doctor-fail
run "npx appium driver doctor uiautomator2 2>&1 | grep -E 'fixes needed|Bye'"

LAB_EXTRA="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"
block doctor-ok-full
run 'npx appium driver doctor uiautomator2'

block doctor
run "npx appium driver doctor uiautomator2 2>&1 | grep -E 'fixes needed|Bye'"

block everywhere
prompt; echo 'npx appium'
start appium 'npx appium' localhost:4723/status
startup | grep -E 'listener started|accessible|^\s+http'
halt_tree appium

block server
prompt; echo 'npx appium --address 127.0.0.1'
start appium 'npx appium --address 127.0.0.1' localhost:4723/status
startup

block status
run 'curl -s localhost:4723/status | jq'

# ---- a-session-by-hand -------------------------------------------------------
block fake-driver
run 'npx appium driver install --source=npm @appium/fake-driver@6.2.4 2>&1 | tail -3'
run "npx appium driver list --installed 2>&1 | grep 'installed ('"

halt_tree appium
block restart
prompt; echo 'npx appium --address 127.0.0.1'
start appium 'npx appium --address 127.0.0.1' localhost:4723/status
startup | grep -E 'Welcome|listener started|Available drivers|  - '

block no-prefix
run "curl -s localhost:4723/session $J -d '{\"capabilities\":{\"alwaysMatch\":{\"platformName\":\"Fake\",\"automationName\":\"Fake\"}}}' | jq '.value | {error, message}'"

block session
OUT=$(run "curl -s localhost:4723/session $J -d @appium/fake-caps.json | jq")
printf '%s\n' "$OUT"
SID=$(printf '%s\n' "$OUT" | sed -n 's/^ *"sessionId": "\(.*\)"$/\1/p')
block session-var
run "SESSION=$SID"
LAB_EXTRA="$LAB_EXTRA SESSION=$SID"

block find
run "curl -s localhost:4723/session/\$SESSION/element $J -d '{\"using\":\"id\",\"value\":\"example.tickets:id/refresh\"}' | jq"

block click
run "curl -s -X POST localhost:4723/session/\$SESSION/element/1/click $J -d '{}'; echo"
run "curl -s localhost:4723/session/\$SESSION/element/1/attribute/clicks; echo"

block missing
run "curl -s localhost:4723/session/\$SESSION/element $J -d '{\"using\":\"id\",\"value\":\"example.tickets:id/remind\"}' | jq '.value | {error, message}'"
run "curl -s -o /dev/null -w '%{http_code}\\n' localhost:4723/session/\$SESSION/element $J -d '{\"using\":\"id\",\"value\":\"example.tickets:id/remind\"}'"

block source
run 'curl -s localhost:4723/session/$SESSION/source | jq -r .value'

block delete
run 'curl -s -X DELETE localhost:4723/session/$SESSION; echo'
run "curl -s localhost:4723/session/\$SESSION/source | jq '.value | {error, message}'"

# ---- first-test --------------------------------------------------------------
block no-device
run 'node --test --test-reporter=tap appium/tickets.test.mjs'

# ---- locators-and-waits ------------------------------------------------------
LINES_BEFORE=$(wc -l < /tmp/lab-appium.log)
block fake-session
run 'node appium/fake-session.mjs'

block wait-log
strip < /tmp/lab-appium.log | tail -n +"$((LINES_BEFORE + 1))" | grep -E '\[HTTP\] (-->|<--) GET .*/displayed' | sed -n '1,6p'

halt_tree appium
quiet 'adb kill-server'
