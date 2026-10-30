#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of android-apps, as a script that
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
# What is STAGED rather than typed: nothing beyond lab.sh's own list.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2, AGP 9.5.0, KSP
# 2.3.12 and Hilt 2.60.1, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
P=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner

project l12
put "$HERE/setup.md" app/build.gradle.kts
put "$HERE/setup.md" $P/PlannerApp.kt
put "$HERE/setup.md" app/src/main/AndroidManifest.xml
put "$HERE/setup.md" $P/MainActivity.kt
put "$HERE/setup.md" $P/data/Model.kt
put "$HERE/setup.md" $P/data/SessionStore.kt
put "$HERE/modules.md" $P/di/StoreModule.kt
put "$HERE/modules.md" $P/di/ClockModule.kt
put "$HERE/hilt-viewmodel.md" $P/ui/WeekViewModel.kt
put "$HERE/hilt-viewmodel.md" $P/ui/WeekScreen.kt
put "$HERE/hilt-viewmodel.md" app/src/main/res/values/strings.xml
put "$HERE/testing.md" $T/WeekHiltTest.kt

block build
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|^e: |error:"'

block generated
run 'find app/build/generated/ksp/debug app/build/generated/hilt -name "*.java" | wc -l'
run 'find app/build/generated/ksp/debug app/build/generated/hilt -name "*.java" | sed "s|.*/||" | sort | grep -E "^(Hilt_|DaggerPlannerApp|PlannerApp_Hilt|WeekViewModel_(Factory|HiltModules)\.)"'

block missing
run "mv $P/di/StoreModule.kt /tmp/"
run './gradlew --console=plain assembleDebug 2>&1 | grep -E -A8 "MissingBinding" | head -9'
run "mv /tmp/StoreModule.kt $P/di/"
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"'

block hilt-test
run './gradlew --console=plain testDebugUnitTest 2>&1 | grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"'
