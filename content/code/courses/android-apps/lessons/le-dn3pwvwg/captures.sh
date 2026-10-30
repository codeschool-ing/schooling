#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here is lifted out of this lesson's .md files by ../../lab.sh, so the file
# built is the block the student copies. The screenshots the tests record are
# copied out to $SHOTS and embedded in the lesson as they were written.
#
# What is STAGED rather than typed:
#   - the project is lesson 1's skeleton, as lesson 1 section 05 leaves it;
#   - each block adds the files of one section and runs only that section's
#     test class with `--tests`, so each listing shows what that section made.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, the Android
# Gradle plugin 9.5.0, Robolectric 4.17 and Roborazzi 1.77.0,
# TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/android-apps-shots/l06}
mkdir -p "$SHOTS"
T=app/src/test/java/com/example/planner
U=app/src/main/java/com/example/planner/ui
rec() { run "./gradlew --console=plain recordRoborazziDebug --tests '*.$1' 2>&1 | grep -E '^BUILD|FAILED'"; }

project l06
put "$HERE/three-containers.md" $U/SessionRow.kt
put "$HERE/three-containers.md" $T/SessionRowTest.kt
quiet './gradlew --console=plain assembleDebug'

block record-rows
rec SessionRowTest
run 'ls app/shots'
shot shots/session-rows.png "$SHOTS/session-rows.png"

block record-cards
put "$HERE/box.md" $U/CourseCard.kt
put "$HERE/box.md" $T/CourseCardTest.kt
rec CourseCardTest
shot shots/course-cards.png "$SHOTS/course-cards.png"

block record-order
put "$HERE/modifier-order.md" $T/ModifierOrderTest.kt
rec ModifierOrderTest
shot shots/modifier-order.png "$SHOTS/modifier-order.png"

block constraints
put "$HERE/constraints.md" $T/ConstraintsTest.kt
run "./gradlew --console=plain testDebugUnitTest --tests '*.ConstraintsTest' 2>&1 | grep -E '^BUILD|FAILED'"
run 'grep "given" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.ConstraintsTest.xml | sed "s/.*CDATA\[//"'

block record-arrangements
put "$HERE/weight-and-arrangement.md" $T/ArrangementTest.kt
rec ArrangementTest
shot shots/arrangements.png "$SHOTS/arrangements.png"

block record-proportional
put "$HERE/custom-layout.md" $U/ProportionalRow.kt
put "$HERE/custom-layout.md" $T/ProportionalRowTest.kt
rec ProportionalRowTest
run 'ls app/shots'
shot shots/proportional.png "$SHOTS/proportional.png"
