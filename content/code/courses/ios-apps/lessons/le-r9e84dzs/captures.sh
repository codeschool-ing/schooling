#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# The package is rebuilt in ~/planner from the lessons it comes from: lesson
# 1's files, lesson 12's (Wire, APIClient, Loadable and the last `fetch`),
# and this lesson's, each lifted out of its .md by ../../lab.sh. The server
# is lesson 12's serve.py, lifted out of its the-server.md.
#
# What is STAGED rather than typed:
#   - the server. The lesson has the student start and stop `python3
#     serve.py` with Ctrl-C in a second terminal. Here `server_on` starts it
#     in the background with setsid and `server_off` kills it, at the points
#     where the lesson says to start and stop it. Its log is not quoted.
#   - planner.json is removed before the first run, so the first refresh
#     starts from a device that has never saved anything, as the lesson
#     says.
#   - `swift build` is piped to `tail -1`, shown as typed.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2 and Python 3.12, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md
L12=$HERE/../le-sqxtw0zb

server_on() { bash "$LAB_SH" exec server '{ setsid python3 serve.py > serve.log 2>&1 < /dev/null & echo $! > serve.pid; }'; sleep 1; }
server_off() { bash "$LAB_SH" exec server 'kill $(cat serve.pid) 2>/dev/null; rm -f serve.pid'; sleep 0.5; }

at .
quiet 'rm -rf ~/planner ~/server && mkdir -p ~/planner/Sources/PlannerCore ~/planner/Sources/week ~/planner/Sources/fetch ~/planner/Sources/repo ~/planner/Tests/PlannerCoreTests ~/server'
at server
put "$L12/the-server.md" serve.py
at planner
for f in Sources/PlannerCore/Plan.swift Sources/PlannerCore/Days.swift Sources/week/main.swift \
         Tests/PlannerCoreTests/PlanTests.swift; do put "$L1" "$f"; done
put "$L12/decoding.md" Sources/PlannerCore/Wire.swift
put "$L12/decoding.md" Tests/PlannerCoreTests/WireTests.swift
put "$L12/status-codes.md" Sources/PlannerCore/APIClient.swift
put "$L12/the-error-state.md" Sources/PlannerCore/Loadable.swift
put "$L12/cancellation.md" Sources/fetch/main.swift
MD=$HERE/the-protocols.md
for f in Package.swift Sources/PlannerCore/PlanSource.swift Sources/PlannerCore/PlanStore.swift; do put "$MD" "$f"; done
MD=$HERE/read-offline-first.md
put "$MD" Sources/PlannerCore/PlannerRepository.swift
put "$MD" Sources/repo/main.swift
put "$HERE/a-fake.md" Tests/PlannerCoreTests/RepositoryTests.swift
quiet 'rm -f planner.json'

block first-offline
run 'swift build | tail -1'
run '.build/debug/repo refresh'

server_on
block online
run '.build/debug/repo refresh'
server_off
block offline-read
run '.build/debug/repo'

block offline-add
run '.build/debug/repo add s5 mobile 2026-10-22 30'
run 'grep -A8 "\"pending\"" planner.json'

server_on
block sync
run '.build/debug/repo sync'
server_off

block tests
run 'swift test 2>&1 | grep -E "✔|✘"'

block unknown
run '.build/debug/repo add s6 art 2026-10-22 30'
