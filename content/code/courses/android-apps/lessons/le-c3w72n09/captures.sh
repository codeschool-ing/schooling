#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of android-apps, as a script that
# produces them, and the two screenshots. Every block of output starts with
# `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh [SHOTDIR]
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here is lifted out of this lesson's .md by ../../lab.sh, so the file built
# is the block the student copies. Week.kt appears twice in unit-tests.md,
# first with the mistake and then fixed, and the build file appears in two
# sections; each block is taken in the order the lesson shows it.
#
# What is STAGED rather than typed:
#   - the project starts as lesson 1 section 05 leaves it (`project`);
#   - the screenshot PNGs, the reference and the comparison, are copied out of
#     the project to SHOTDIR and embedded in screenshot-tests.md;
#   - `connectedDebugAndroidTest` was run on a machine with no device and no
#     emulator, and its refusal is the transcript; no instrumented test ran.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2, AGP 9.5.0,
# Robolectric 4.17 and Roborazzi 1.77.0, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${1:-/tmp}
P=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner
F="grep -E '^    |PASSED|FAILED|^BUILD|tests completed'"

block unit-fail
project l21
MD=$HERE/unit-tests.md
put "$MD" app/build.gradle.kts
put "$MD" $P/data/Week.kt 1
put "$MD" $T/data/WeekTest.kt
run "./gradlew --console=plain testDebugUnitTest --tests '*WeekTest' 2>&1 | $F"
run "grep -ho 'message=\"[^\"]*\"' app/build/test-results/testDebugUnitTest/*.xml"

block unit-pass
put "$MD" $P/data/Week.kt 2
run "./gradlew --console=plain testDebugUnitTest --tests '*WeekTest' 2>&1 | $F"

block compose-test
MD=$HERE/compose-ui-tests.md
for f in app/src/main/res/values/strings.xml $P/ui/WeekScreen.kt $T/ui/WeekScreenTest.kt; do put "$MD" "$f"; done
run "./gradlew --console=plain testDebugUnitTest --tests '*WeekScreenTest' 2>&1 | $F"

block deprecated
run "./gradlew --console=plain compileDebugUnitTestKotlin --rerun 2>&1 | grep '^w: .*WeekScreenTest'"
run "sed -i 's/junit4.createComposeRule/junit4.v2.createComposeRule/' $T/ui/WeekScreenTest.kt"
run "./gradlew --console=plain testDebugUnitTest --tests '*WeekScreenTest' 2>&1 | $F"

block record
MD=$HERE/screenshot-tests.md
put "$MD" $T/ui/WeekShotTest.kt
run "./gradlew --console=plain recordRoborazziDebug --tests '*WeekShotTest' 2>&1 | $F"
run 'ls -l app/screenshots/'
shot screenshots/week.png "$SHOTS/l21-week.png"

block verify-ok
run "./gradlew --console=plain verifyRoborazziDebug --tests '*WeekShotTest' 2>&1 | $F"

block verify-fail
run "sed -i 's/padding(16.dp)) {/padding(24.dp)) {/' $P/ui/WeekScreen.kt"
run "./gradlew --console=plain verifyRoborazziDebug --tests '*WeekShotTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD|What went wrong' -A1 | grep -v '^--'"
run 'ls app/build/outputs/roborazzi/'
shot build/outputs/roborazzi/week_compare.png "$SHOTS/l21-week-compare.png"
quiet "sed -i 's/padding(24.dp)) {/padding(16.dp)) {/' $P/ui/WeekScreen.kt"

block connected
MD=$HERE/instrumented-tests.md
put "$MD" app/build.gradle.kts
put "$MD" app/src/androidTest/java/com/example/planner/ui/WeekScreenDeviceTest.kt
run "./gradlew --console=plain connectedDebugAndroidTest 2>&1 | grep -E -A2 'What went wrong|^BUILD' | grep -v '^--'"
run 'adb devices'
quiet 'adb kill-server'

block timings
run "./gradlew --console=plain testDebugUnitTest --rerun 2>&1 | grep -E '^BUILD|tests completed'"
run "grep -ho 'testcase name=\"[^\"]*\" classname=\"[^\"]*\" time=\"[^\"]*\"' app/build/test-results/testDebugUnitTest/*.xml | sed -e 's/classname=\"com.example.planner.//'"
