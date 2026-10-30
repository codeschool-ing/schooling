#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The project is
# lesson 1's skeleton; every file this lesson adds or changes is lifted out of
# the lesson's own .md by ../../lab.sh, so the file built is the block the
# student copies.
#
# What is STAGED rather than typed:
#   - SaverTest.kt is written twice, as savers.md shows it twice: first the
#     version that fails, then the one with a Saver;
#   - the test output is long, and each transcript keeps the planner's lines
#     with a `grep` that is part of the command shown;
#   - the two screenshots RotationTest writes are copied off the machine.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, Android
# Gradle plugin 9.5.0, Compose BOM 2026.09.00 and Robolectric 4.17,
# TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/claude-0/-home-user-schooling/a10c356e-38bc-5069-a127-122e1cefc2dc/scratchpad/shots-a}
P=/var/lib/machines/android-lab/home/ana/w/l04/planner

project l04
put "$HERE/state-triggers.md" app/src/test/java/com/example/planner/StateTest.kt
put "$HERE/state-triggers.md" app/build.gradle.kts
put "$HERE/rotation.md" app/src/main/java/com/example/planner/ui/TwoCounters.kt
put "$HERE/hoisting.md" app/src/main/res/values/strings.xml
put "$HERE/rotation.md" app/src/main/java/com/example/planner/MainActivity.kt
put "$HERE/rotation.md" app/src/test/java/com/example/planner/RotationTest.kt
put "$HERE/hoisting.md" app/src/main/java/com/example/planner/ui/NewSession.kt
put "$HERE/hoisting.md" app/src/test/java/com/example/planner/HoistingTest.kt
put "$HERE/savers.md" app/src/test/java/com/example/planner/SaverTest.kt 1
quiet './gradlew --console=plain compileDebugUnitTestKotlin'

block three-counters
run './gradlew --console=plain testDebugUnitTest --tests "*StateTest" 2>&1 | grep -E "after one click|^BUILD"'

block rotation
run './gradlew --console=plain recordRoborazziDebug --tests "*RotationTest" 2>&1 | grep -E "the rotation|^BUILD"'
cp "$P/app/screenshots/before-rotation.png" "$SHOTS/l04-before.png"
cp "$P/app/screenshots/after-rotation.png" "$SHOTS/l04-after.png"

block saver-fails
run './gradlew --console=plain testDebugUnitTest --tests "*SaverTest" 2>&1 | grep -E "FAILED|Exception|tests completed|^BUILD"'
run 'grep -o "message=\"[^\"]*\"" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.SaverTest.xml'

block saver-passes
put "$HERE/savers.md" app/src/test/java/com/example/planner/SaverTest.kt 2
run './gradlew --console=plain testDebugUnitTest --tests "*SaverTest" 2>&1 | grep -E "FAILED|tests completed|^BUILD"'

block hoisting
run './gradlew --console=plain testDebugUnitTest --tests "*HoistingTest" 2>&1 | grep -E "owner shows|^BUILD"'
