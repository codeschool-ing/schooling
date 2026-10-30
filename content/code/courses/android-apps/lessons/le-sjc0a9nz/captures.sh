#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here is lifted out of this lesson's .md files by ../../lab.sh. The
# screenshots the tests record are copied out to $SHOTS and embedded in the
# lesson as they were written.
#
# What is STAGED rather than typed:
#   - the project is lesson 1's skeleton, as lesson 1 section 05 leaves it;
#   - each block runs one test class with `--tests`.
#
# Robolectric has no wallpaper: the dynamic colours on SDK 35 are whatever its
# copy of Android 15 returns, and the lesson says so.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, the Android
# Gradle plugin 9.5.0, Compose BOM 2026.09.00, Robolectric 4.17 and Roborazzi
# 1.77.0, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/android-apps-shots/l07}
mkdir -p "$SHOTS"
T=app/src/test/java/com/example/planner
U=app/src/main/java/com/example/planner/ui

project l07
put "$HERE/colour-roles.md" $U/theme/Theme.kt
put "$HERE/type-and-shape.md" $U/theme/Type.kt
put "$HERE/type-and-shape.md" $U/WeekSummary.kt
put "$HERE/dark-mode.md" $T/ThemeTest.kt
put "$HERE/dynamic-colour.md" $T/DynamicColorTest.kt
put "$HERE/contrast.md" $T/ContrastTest.kt
quiet './gradlew --console=plain assembleDebug'

block record-theme
run "./gradlew --console=plain recordRoborazziDebug --tests '*.ThemeTest' 2>&1 | grep -E '^BUILD|FAILED'"
run 'ls app/shots'
shot shots/week-light.png "$SHOTS/week-light.png"
shot shots/week-dark.png "$SHOTS/week-dark.png"

block dynamic
run "./gradlew --console=plain recordRoborazziDebug --tests '*.DynamicColorTest' 2>&1 | grep -E '^BUILD|FAILED'"
run 'grep -h -e "SDK " -e "[0-9]:1$" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.DynamicColorTest.xml | sed "s/.*CDATA\[//"'
shot shots/week-dynamic.png "$SHOTS/week-dynamic.png"

block contrast
run "./gradlew --console=plain testDebugUnitTest --tests '*.ContrastTest' 2>&1 | grep -E '^BUILD|FAILED'"
run 'grep ":1" app/build/test-results/testDebugUnitTest/TEST-com.example.planner.ContrastTest.xml | sed "s/.*CDATA\[//"'
