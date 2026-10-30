#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file of the planner package is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies. The
# package grows section by section: each section writes the files it shows
# over the ones before, and nothing else.
#
# THE NETWORK. Section 04 fetches swift-argument-parser from GitHub through
# the recording machine's proxy, which lab.sh stages and no lesson prints.
# ~/.cache/org.swift.swiftpm is emptied first, so the fetch is a first fetch.
#
# Timings and progress lines are this run's. `grep -v frontend` drops the
# compiler's command line a failed build prints, as lesson 17 explained.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
G='grep -v frontend'

fresh sw/l19
quiet 'rm -rf ~/.cache/org.swift.swiftpm; mkdir -p hello planner/Sources/PlannerCore planner/Sources/plan'

at sw/l19/hello
block anatomy-init
run 'swift package init --type executable'
run "find . -path ./.build -prune -o -type f -print | sort"
block anatomy-manifest
run 'cat Package.swift'
block anatomy-source
run 'cat Sources/hello/hello.swift'
block anatomy-run
run "swift run 2>&1 | $G"

at sw/l19/planner
MD=$HERE/targets-products.md
put "$MD" Package.swift
put "$MD" Sources/PlannerCore/Week.swift
put "$MD" Sources/plan/main.swift
block targets-describe
run 'swift package describe'
block targets-build
run "swift build 2>&1 | tail -1"
run 'ls .build/debug'
run '.build/debug/plan 45 30 60'

MD=$HERE/dependencies.md
put "$MD" Package.swift
put "$MD" Sources/plan/Plan.swift
block deps-resolve
run 'rm Sources/plan/main.swift'
run 'swift package resolve'
block deps-build
run "swift build 2>&1 | tail -1"
run '.build/debug/plan 45 30 60'
run '.build/debug/plan --goal 120 45 30 60'
run '.build/debug/plan --help'
run '.build/debug/plan 45 forty; echo $?'

MD=$HERE/resolved.md
block resolved-file
run 'cat Package.resolved'
block resolved-graph
run 'swift package show-dependencies'
block resolved-narrow
run "sed -i 's/from: \"1.6.0\"/.upToNextMinor(from: \"1.6.0\")/' Package.swift"
run 'grep argument-parser Package.swift'
run 'swift package resolve'
block resolved-keep
run "sed -i 's/.upToNextMinor(from: \"1.6.0\")/from: \"1.6.0\"/' Package.swift"
run 'swift package resolve'
run "grep '\"version\" : \"1' Package.resolved"
block resolved-update
run 'swift package update'
run "grep '\"version\" : \"1' Package.resolved"

MD=$HERE/configurations.md
put "$MD" Sources/PlannerCore/Week.swift
block config-debug
run "swift build 2>&1 | tail -1"
run '.build/debug/plan 45 0 2>&1 | head -3'
block config-release
run "swift build -c release 2>&1 | tail -1"
run '.build/release/plan 45 0'
block config-size
run 'ls -l .build/debug/plan .build/release/plan'
block config-speed
run 'time .build/debug/plan $(seq 1 3000)'
run 'time .build/release/plan $(seq 1 3000)'

MD=$HERE/toolchain.md
block toolchain-versions
run 'swift --version'
run 'swift package tools-version'
run 'touch Sources/PlannerCore/Week.swift'
run "swift build -v 2>&1 | grep -o -e '-swift-version [0-9]*' | uniq -c"
block toolchain-mode
run 'swift package tools-version --set 5.10'
run 'head -2 Package.swift'
run 'touch Sources/PlannerCore/Week.swift'
run "swift build -v 2>&1 | grep -o -e '-swift-version [0-9]*' | uniq -c"
run 'swift package tools-version --set 6.2'
run 'head -2 Package.swift'
block toolchain-bin
run 'ls ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin | wc -l'
run 'du -sh .build ~/.cache/org.swift.swiftpm'
