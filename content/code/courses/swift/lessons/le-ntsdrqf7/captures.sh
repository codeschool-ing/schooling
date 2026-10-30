#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here, Package.swift included, is lifted out of
# this lesson's .md by ../../lab.sh, so the file compiled is the block the
# student copies. The planner package grows from section to section: each
# section writes the files it shows over the ones before, and nothing else.
#
# `grep -v frontend` drops the compiler's full command line, which a failed
# `swift build` prints, as the lesson says in section 03.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
B='swift build 2>&1 | grep -v frontend'

fresh sw/l17
quiet 'mkdir -p levels planner report'

at sw/l17/levels
MD=$HERE/levels.md
block levels-refused
put "$MD" Week.swift
put "$MD" main.swift 1
run 'swiftc Week.swift main.swift -o week'
block levels-fixed
put "$MD" main.swift 2
run 'swiftc Week.swift main.swift -o week && ./week'

at sw/l17/planner
MD=$HERE/modules.md
put "$MD" Package.swift
put "$MD" Sources/plan/main.swift
block modules-internal
put "$MD" Sources/PlannerCore/Week.swift 1
run "$B"
block modules-init
put "$MD" Sources/PlannerCore/Week.swift 2
run "$B"
block modules-public
put "$MD" Sources/PlannerCore/Week.swift 3
run "$B"
run '.build/debug/plan'

MD=$HERE/private-set.md
put "$MD" Sources/PlannerCore/Week.swift
block privateset-refused
put "$MD" Sources/plan/main.swift 1
run "$B"
block privateset-fixed
put "$MD" Sources/plan/main.swift 2
run "$B"
run '.build/debug/plan'

MD=$HERE/open.md
put "$MD" Sources/plan/main.swift
block open-refused
put "$MD" Sources/PlannerCore/Reminder.swift 1
run "$B"
block open-fixed
put "$MD" Sources/PlannerCore/Reminder.swift 2
run "$B"
run '.build/debug/plan'

MD=$HERE/package.md
put "$MD" Sources/PlannerCore/Week.swift
put "$MD" Sources/plan/main.swift
block package-inside
run "$B"
run '.build/debug/plan'
at sw/l17/report
put "$MD" Package.swift
put "$MD" Sources/report/main.swift
block package-outside
run "$B"

at sw/l17/planner
MD=$HERE/namespaces.md
put "$MD" Sources/PlannerCore/Goals.swift
block namespaces-refused
put "$MD" Sources/plan/main.swift 1
run "$B"
block namespaces-fixed
put "$MD" Sources/plan/main.swift 2
run "$B"
run '.build/debug/plan'
