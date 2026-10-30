#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of android-apps, as a script that
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
#   - app/build.gradle.kts is written twice, as the lesson shows it twice:
#     lesson 2's file for sections 02 and 03, then with the composeCompiler
#     block for section 04; stability.conf is written twice too, empty and
#     then with one class in it;
#   - each test class runs on its own with --tests, because the tests count
#     runs in one shared map and a run of all of them would mix the counts;
#   - the test output is long, and each transcript keeps the planner's lines
#     with a `grep` that is part of the command shown.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, Android
# Gradle plugin 9.5.0, Kotlin 2.4.21, Compose BOM 2026.09.00 and Robolectric
# 4.17, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

project l05
put "$HERE/what-triggers.md" app/build.gradle.kts
put "$HERE/what-triggers.md" app/src/test/java/com/example/planner/RecompositionTest.kt
put "$HERE/skipping.md" app/src/main/java/com/example/planner/data/StudySession.kt
put "$HERE/skipping.md" app/src/test/java/com/example/planner/SkippingTest.kt
put "$HERE/derived-state.md" app/src/test/java/com/example/planner/DerivedTest.kt
put "$HERE/keys.md" app/src/test/java/com/example/planner/KeyTest.kt
quiet './gradlew --console=plain compileDebugUnitTestKotlin'

block triggers
run './gradlew --console=plain testDebugUnitTest --tests "*RecompositionTest" 2>&1 | grep -E "after 3|^BUILD"'

block skipping
run './gradlew --console=plain testDebugUnitTest --tests "*SkippingTest" 2>&1 | grep -E "after 3|^BUILD"'

block classes-before
put "$HERE/compiler-reports.md" app/build.gradle.kts
put "$HERE/compiler-reports.md" stability.conf 1
run './gradlew --console=plain clean compileDebugKotlin 2>&1 | grep -E "^BUILD"'
run 'cat app/build/compose_compiler/app-classes.txt'

block composables
run './gradlew --console=plain compileDebugUnitTestKotlin 2>&1 | grep -E "^BUILD"'
run 'grep -A3 -E "fun com.example.planner.(SessionCount|DraftMinutes)" app/build/compose_compiler/app-composables.txt'

block flags
run 'grep -A5 featureFlags app/build/compose_compiler/debug/app-module.json'

block classes-after
put "$HERE/compiler-reports.md" stability.conf 2
run './gradlew --console=plain clean compileDebugKotlin 2>&1 | grep -E "^BUILD"'
run 'grep -A7 StudySession app/build/compose_compiler/app-classes.txt'

block derived
run './gradlew --console=plain testDebugUnitTest --tests "*DerivedTest" 2>&1 | grep -E "after 14|^BUILD"'

block keys
run './gradlew --console=plain testDebugUnitTest --tests "*KeyTest" 2>&1 | grep -E "key:|^BUILD"'
