#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The project is
# lesson 1's skeleton, and every file added here is lifted out of this
# lesson's .md files by ../../lab.sh, so the file built is the block the
# student copies.
#
# What is STAGED rather than typed: nothing beyond lab.sh's own list. The
# screenshot the shot-test block writes is copied out of the machine and
# embedded in one-way-flow.md as a figure.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2 and AGP 9.5.0,
# TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/android-apps-shots}
P=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner
G='grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    (before|after|same)"'

project l10
put "$HERE/ui-state.md" app/build.gradle.kts
put "$HERE/ui-state.md" $P/data/Model.kt
put "$HERE/ui-state.md" $P/ui/WeekViewModel.kt
put "$HERE/one-way-flow.md" $P/ui/WeekScreen.kt
put "$HERE/one-way-flow.md" $P/MainActivity.kt
put "$HERE/one-way-flow.md" app/src/main/res/values/strings.xml
put "$HERE/one-way-flow.md" $T/ui/WeekScreenShotTest.kt
put "$HERE/surviving.md" $T/RecreateTest.kt
put "$HERE/saved-state.md" $T/ProcessDeathTest.kt
put "$HERE/testing.md" $T/ui/WeekViewModelTest.kt
quiet './gradlew --console=plain assembleDebug'

block shot-test
run "./gradlew --console=plain testDebugUnitTest --tests '*WeekScreenShotTest' -Proborazzi.test.record=true 2>&1 | $G"
shot screenshots/week.png "$SHOTS/l10-week.png"

block recreate
run "./gradlew --console=plain testDebugUnitTest --tests '*RecreateTest' 2>&1 | $G"

block process
run "./gradlew --console=plain testDebugUnitTest --tests '*ProcessDeathTest' 2>&1 | $G"

block unit
run "./gradlew --console=plain testDebugUnitTest --tests '*WeekViewModelTest' 2>&1 | $G"

block lint
put "$HERE/what-not-to-hold.md" $P/ui/LeakyViewModel.kt
run './gradlew --console=plain lintDebug 2>&1 | grep -E "^BUILD"'
run 'grep -A2 "\[StaticFieldLeak\]" app/build/reports/lint-results-debug.txt'
