#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of android-apps, as a script that
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
#   - the test output is long (Robolectric's own log, androidx.test's), and
#     each transcript keeps the planner's lines with a `grep` that is part of
#     the command shown;
#   - the screenshot the window test writes is copied off the machine to be
#     embedded in set-content.md.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, Android
# Gradle plugin 9.5.0 and Robolectric 4.17, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/claude-0/-home-user-schooling/a10c356e-38bc-5069-a127-122e1cefc2dc/scratchpad/shots-a}

project l02
put "$HERE/an-activity.md" app/src/main/java/com/example/planner/MainActivity.kt
put "$HERE/the-lifecycle.md" app/src/test/java/com/example/planner/LifecycleTest.kt
put "$HERE/the-lifecycle.md" app/build.gradle.kts
put "$HERE/set-content.md" app/src/test/java/com/example/planner/WindowTest.kt
quiet './gradlew --console=plain testDebugUnitTest'

block home-and-back
run './gradlew --console=plain testDebugUnitTest --rerun --tests "*LifecycleTest.homeAndBack" 2>&1 | grep -E "STANDARD_OUT|Lifecycle:|  --|^BUILD"'

block rotation
run './gradlew --console=plain testDebugUnitTest --rerun --tests "*LifecycleTest.rotation" 2>&1 | grep -E "STANDARD_OUT|Lifecycle:|  --|^BUILD"'

block window
run './gradlew --console=plain recordRoborazziDebug --rerun --tests "*WindowTest" 2>&1 | grep -E "STANDARD_OUT|views in|the view|^BUILD"'
shot screenshots/welcome.png "$SHOTS/l02-welcome.png"
