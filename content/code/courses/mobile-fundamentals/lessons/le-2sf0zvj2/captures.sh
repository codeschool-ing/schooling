#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of mobile-fundamentals, as a script
# that produces them. The output is not committed: lab/fill.py pastes each
# block into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner holds lesson 1's planner.ts and package.json, taken out of
#     lesson 1's the-planner.md, as the student has them by now.
#   - payload.ts and reminders.ts are taken out of this lesson's sections by
#     lab/extract.py, so the program each transcript ran is the one the lesson
#     prints.
#   - Nothing is sent to FCM or APNs: payload.ts prints the messages and their
#     sizes, and the token in them is a stand-in string.
#   - reminders.ts is given "now", so it prints the same reminders on every run.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md planner.ts $P/planner.ts
put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put the-message.md payload.ts $P/payload.ts
put local-reminders.md reminders.ts $P/reminders.ts

block payload
run $P 'node payload.ts'

block reminders
run $P 'node reminders.ts 2026-10-21T12:00:00-03:00'
