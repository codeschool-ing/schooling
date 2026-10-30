#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here, Package.swift included, is lifted out of
# this lesson's .md by ../../lab.sh, so the file compiled is the block the
# student copies. Nothing is staged.
#
# NOT DETERMINISTIC, ON PURPOSE: `race` and `pkg5` print totals that a data
# race decides, and they differ on every run and on every machine; `booking`
# and `reserved` may name the two courses in either order. The lesson says so
# where it quotes them. The recording machine has 4 cores.
#
# `swift build` colours its diagnostics and wraps the diagnostic names in
# terminal hyperlinks even when its output is a pipe; _strip is widened here
# to remove those escapes as well, and keep the words.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
_strip() { sed -e $'s/\x1b\\[[0-9;]*[mK]//g' -e $'s/\x1b]8;;[^\x1b]*\x1b\\\\//g'; }

fresh sw/l15
MD=$HERE/data-race.md
sc Race.swift race
block race6
run 'swiftc -swift-version 6 Race.swift -o race'
MD=$HERE/actors.md
block actor
put "$MD" Actor.swift
run 'swiftc -swift-version 6 Actor.swift -o actor && ./actor'
block outside
put "$MD" Outside.swift
run 'swiftc -swift-version 6 Outside.swift -o outside'
MD=$HERE/isolation.md
for f in Booking Reserved; do
  block "$(echo $f | tr A-Z a-z)"
  put "$MD" $f.swift
  run "swiftc -swift-version 6 $f.swift -o $(echo $f | tr A-Z a-z) && ./$(echo $f | tr A-Z a-z)"
done
MD=$HERE/sendable.md
for f in Sendables Handover Course; do
  block "$(echo $f | tr A-Z a-z)"
  put "$MD" $f.swift
  if [ $f = Course ]; then run "swiftc -swift-version 6 $f.swift -o course"
  else run "swiftc -swift-version 6 $f.swift -o $(echo $f | tr A-Z a-z) && ./$(echo $f | tr A-Z a-z)"; fi
done
MD=$HERE/main-actor.md
for f in Screen ScreenFixed Inherit; do
  block "$(echo $f | tr A-Z a-z)"
  put "$MD" $f.swift
  if [ $f = ScreenFixed ]; then run "swiftc -swift-version 6 $f.swift -o screenfixed && ./screenfixed"
  else run "swiftc -swift-version 6 $f.swift -o $(echo $f | tr A-Z a-z)"; fi
done
MD=$HERE/language-modes.md
fresh sw/l15/race
put "$MD" Package.swift 1
put "$MD" Sources/Race/main.swift
block pkg6
run "swift build 2>&1 | grep -E '^/[^ ]+[.]swift:|^error: Build|^Build'"
put "$MD" Package.swift 2
block pkg5
run "swift build 2>&1 | grep -E '^/[^ ]+[.]swift:|^error: Build|^Build'"
run 'swift run Race 2>/dev/null'
fresh sw/l15/week
block init
run 'swift package init --type library --name Week'
run 'grep -n -A2 swiftSettings Package.swift'
run "head -1 Package.swift"
