#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of api-mobile-automation, as the
# script that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT RAN AND WHAT COULD NOT. Espresso runs inside an Android device, and the
# test files need androidx libraries from Google's Maven repository, which this
# sandbox cannot reach; there is no emulator either (lesson 14). So nothing of
# Espresso ran: the three Kotlin files under src/androidTest were neither
# compiled by Gradle nor run, and the lesson says so. What is recorded:
#   - the app's own sources still compile against Android 35 (`lab.sh
#     appcheck`, as in lesson 14), since this lesson adds nothing to src/main;
#   - boxoffice's list of shows, which the tests name by id, title and price;
#   - where the app counts its loads, read from its source with grep;
#   - the two kinds of address a test can point the app at to make it fail,
#     tried with curl from the computer: a port nothing listens on, refused at
#     once, and an address nothing answers, which waits for the timeout;
#   - the command Gradle runs on the device, typed with no device attached.
# STAGED: boxoffice is started in the background where the lesson has it
# running in a terminal of its own, and adb's server is stopped at the end, as
# lesson 14's captures do.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0, jq 1.7.1
# and platform-tools 36.0.0, TZ=America/Sao_Paulo, as user ana.

source "$(dirname "$0")/../../lab.sh"
project 16 /home/ana/boxoffice
lab_appcheck /home/ana/boxoffice >&2 || { echo "captures: the app does not compile" >&2; exit 1; }
here /home/ana/boxoffice
quiet 'adb kill-server'

serve api 'node boxoffice.mjs'

block shows
run "curl -s localhost:8080/v1/shows | jq -r '.shows[] | \"\\(.id)  \\(.price_cents)  \\(.title)\"'"

block busy
run 'grep -n busy tickets/app/src/main/java/example/tickets/*.kt'

block refused
run 'curl -sS --connect-timeout 5 http://localhost:9/v1/shows; echo "exit $?"'

block unanswered
run 'curl -sS --connect-timeout 5 http://10.255.255.1:8080/v1/shows; echo "exit $?"'

block instrument
run 'adb shell am instrument -w example.tickets.test/androidx.test.runner.AndroidJUnitRunner'

halt api
quiet 'adb kill-server'
