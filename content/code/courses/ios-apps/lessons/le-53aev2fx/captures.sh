#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# The package is rebuilt in ~/planner from the lessons it comes from: lesson
# 1's files, lesson 12's and lesson 14's, and this lesson's, each lifted out
# of its .md by ../../lab.sh. The covers are made in ~/images by this
# lesson's make_covers.py, lifted the same way.
#
# What is STAGED rather than typed:
#   - the image server. The lesson has the student run `python3 -m
#     http.server 8015 --bind 127.0.0.1` in ~/images, in a terminal of its
#     own. Here the same command is started in the background with setsid
#     and killed at the end; the block `make` prints the command as the
#     student types it, and the line the server prints when it starts,
#     which is the first line of its log (started with `python3 -u`, so that
#     line is written at once rather than when the buffer fills; the student's
#     terminal shows it at once anyway). Its per-request log, which carries
#     the time of every request, is not quoted.
#   - `swift build` is piped to `tail -1`, shown as typed.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2 and Python 3.12, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
L1=$HERE/../le-r8sx9rjk/the-package.md
L12=$HERE/../le-sqxtw0zb
L14=$HERE/../le-r9e84dzs

at .
quiet 'rm -rf ~/planner ~/images && mkdir -p ~/planner/Sources/PlannerCore ~/planner/Sources/week ~/planner/Sources/fetch ~/planner/Sources/repo ~/planner/Sources/covers ~/planner/Tests/PlannerCoreTests ~/images'
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
MD=$HERE/memory-sums.md
for f in Package.swift Sources/PlannerCore/ImageSize.swift Sources/covers/main.swift; do put "$MD" "$f"; done

at images
put "$MD" make_covers.py
block make
run 'python3 make_covers.py'
_prompt images 'python3 -m http.server 8015 --bind 127.0.0.1'
bash "$LAB_SH" exec images '{ setsid python3 -u -m http.server 8015 --bind 127.0.0.1 > http.log 2>&1 < /dev/null & echo $! > http.pid; }; sleep 1; head -1 http.log'

at planner
block sums
run 'swift build | tail -1'
run '.build/debug/covers'

put "$HERE/the-cache.md" Sources/PlannerCore/ImageCache.swift
put "$HERE/the-cache.md" Sources/covers/main.swift
block cache
run 'swift build | tail -1'
run '.build/debug/covers'

at images
quiet 'kill $(cat http.pid); rm -f http.pid http.log'
