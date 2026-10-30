#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# The package is rebuilt in ~/planner from the lessons it comes from: lesson
# 1's files, lesson 12's, 14's and 15's, and this lesson's, each lifted out
# of its .md by ../../lab.sh. The server is lesson 12's serve.py.
#
# What is STAGED rather than typed:
#   - the server, started and stopped by `server_on` and `server_off` where
#     the lesson tells the student to start it or stop it with Ctrl-C in a
#     second terminal. Its log is kept in ~/server/serve.log and copied to
#     $LOG for the author to check the lesson's sentence about it; it is not
#     quoted.
#   - planner.json is removed before the first refresh, so the device starts
#     from nothing, as the lesson's count of six waiting sessions assumes.
#   - `swift build` is piped to `tail -1`, shown as typed.
#   - the run block depends on time: each post waits 400 ms in SlowSource,
#     so a budget of one second fits two posts. It is what this machine did.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2 and Python 3.12, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md
L12=$HERE/../le-sqxtw0zb
L14=$HERE/../le-r9e84dzs
L15=$HERE/../le-53aev2fx
LOG=${LOG:-/tmp/l16-serve.log}

server_on() { bash "$LAB_SH" exec server '{ setsid python3 serve.py > serve.log 2>&1 < /dev/null & echo $! > serve.pid; }'; sleep 1; }
server_off() { bash "$LAB_SH" exec server 'kill $(cat serve.pid) 2>/dev/null; rm -f serve.pid'; sleep 0.5; }

at .
quiet 'rm -rf ~/planner ~/server && mkdir -p ~/planner/Sources/PlannerCore ~/planner/Sources/week ~/planner/Sources/fetch ~/planner/Sources/repo ~/planner/Sources/covers ~/planner/Sources/background ~/planner/Tests/PlannerCoreTests ~/server'
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
put "$L14/the-protocols.md" Sources/PlannerCore/PlanSource.swift
put "$L14/the-protocols.md" Sources/PlannerCore/PlanStore.swift
put "$L14/read-offline-first.md" Sources/PlannerCore/PlannerRepository.swift
put "$L14/read-offline-first.md" Sources/repo/main.swift
put "$L14/a-fake.md" Tests/PlannerCoreTests/RepositoryTests.swift
put "$L15/memory-sums.md" Sources/PlannerCore/ImageSize.swift
put "$L15/the-cache.md" Sources/PlannerCore/ImageCache.swift
put "$L15/the-cache.md" Sources/covers/main.swift
MD=$HERE/scheduling-logic.md
for f in Package.swift Sources/PlannerCore/RefreshPolicy.swift Sources/background/main.swift; do put "$MD" "$f"; done

block next
run 'swift build | tail -1'
run '.build/debug/background America/Sao_Paulo 2026-10-21T22:30:00-03:00'
run '.build/debug/background Europe/Lisbon 2026-10-24T22:30:00+01:00'

MD=$HERE/expiration.md
put "$MD" Sources/PlannerCore/BackgroundSync.swift
put "$MD" Sources/background/main.swift
quiet 'rm -f planner.json'
server_on
block queue
run 'swift build | tail -1'
run '.build/debug/repo refresh | head -1'
server_off
run 'for n in 1 2 3 4 5 6; do .build/debug/repo add b$n mobile 2026-10-22 20 | head -1; done'
run '.build/debug/background'

server_on
block run
run '.build/debug/background run 1.0'
run '.build/debug/background run 1.0'
run '.build/debug/background run 1.0'
server_off
cp /var/lib/machines/ios-lab/home/ana/server/serve.log "$LOG"

put "$HERE/testing-it.md" Tests/PlannerCoreTests/BackgroundTests.swift
block tests
run 'swift test 2>&1 | grep -E "✔|✘"'
