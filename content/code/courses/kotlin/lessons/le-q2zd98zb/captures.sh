#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   (the captures of lessons 14 to 17, which build ~/kt/planner)
#   sudo bash captures.sh
#
# Every file is lifted out of this lesson's .md by ../../lab.sh into the
# project lesson 14 built, so the file tested is the block the student copies.
#
# What is STAGED rather than typed:
#   - src/test is emptied first, so a second recording starts where the
#     student does;
#   - the fix in "Reading a failing test", and the opt-in added to
#     VirtualTimeTest.kt in "runTest and virtual time", are made with sed, where
#     the student edits the file by hand;
#   - Maven Central is reached through the recording mirror lab.sh describes.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21, Gradle 9.8.2 and kotlinx-coroutines 1.11.0, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

at kt/planner
quiet 'rm -rf src/test src/main/kotlin/Totals.kt'
MD=$HERE/first-test.md
put "$MD" build.gradle.kts
put "$MD" src/test/kotlin/DescribeTest.kt
block first
run './gradlew test'
MD=$HERE/assertions.md
put "$MD" src/test/kotlin/WeekTotalTest.kt
block assertions
run './gradlew test --tests WeekTotalTest'
MD=$HERE/when-it-fails.md
put "$MD" src/test/kotlin/SummaryTest.kt
block fails
run './gradlew test --tests SummaryTest'
quiet 'sed -i "s/135 mins/135 min/" src/test/kotlin/SummaryTest.kt'
block fixed
run './gradlew test --tests SummaryTest'
MD=$HERE/run-test.md
put "$MD" src/test/kotlin/VirtualTimeTest.kt
block virtual
run './gradlew test --tests VirtualTimeTest'
quiet 'sed -i -e "s/^import kotlinx.coroutines.delay$/import kotlinx.coroutines.ExperimentalCoroutinesApi\nimport kotlinx.coroutines.delay/" -e "s/^class VirtualTimeTest {/@OptIn(ExperimentalCoroutinesApi::class)\nclass VirtualTimeTest {/" src/test/kotlin/VirtualTimeTest.kt'
block optin
run './gradlew test --tests VirtualTimeTest'
MD=$HERE/scheduler.md
put "$MD" src/test/kotlin/SchedulerTest.kt
block scheduler
run './gradlew test --tests SchedulerTest'
MD=$HERE/failures.md
put "$MD" src/test/kotlin/FailureTest.kt
block failures
run './gradlew test --tests FailureTest'
MD=$HERE/testing-flows.md
put "$MD" src/main/kotlin/Totals.kt
put "$MD" src/test/kotlin/FlowTest.kt
block flows
run './gradlew test --tests FlowTest'
