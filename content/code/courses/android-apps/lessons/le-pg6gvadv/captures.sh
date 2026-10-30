#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of android-apps, as a script that
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
# screenshot the snackbar block writes is copied out of the machine and
# embedded in effects.md as a figure.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2 and AGP 9.5.0,
# TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/android-apps-shots}
P=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner
G='grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-z]"'

project l11
put "$HERE/view-model-scope.md" app/build.gradle.kts
put "$HERE/view-model-scope.md" $P/data/Model.kt
put "$HERE/view-model-scope.md" $P/data/SessionStore.kt
put "$HERE/state-in.md" $P/ui/WeekViewModel.kt
put "$HERE/lifecycle-collection.md" $P/ui/WeekScreen.kt
put "$HERE/lifecycle-collection.md" app/src/main/res/values/strings.xml
put "$HERE/lifecycle-collection.md" $P/MainActivity.kt
put "$HERE/view-model-scope.md" $T/ui/CancelTest.kt
put "$HERE/lifecycle-collection.md" $T/SubscriptionTest.kt
put "$HERE/effects.md" $T/SnackbarTest.kt
put "$HERE/testing-flows.md" $T/ui/WeekViewModelTest.kt
quiet './gradlew --console=plain assembleDebug'

block cancel
run "./gradlew --console=plain testDebugUnitTest --tests '*CancelTest' 2>&1 | $G"

block subscribers
run "./gradlew --console=plain testDebugUnitTest --tests '*SubscriptionTest' 2>&1 | $G"

block snackbar
run "./gradlew --console=plain testDebugUnitTest --tests '*SnackbarTest' -Proborazzi.test.record=true 2>&1 | $G"
shot screenshots/added.png "$SHOTS/l11-added.png"

block unit
run "./gradlew --console=plain testDebugUnitTest --tests '*WeekViewModelTest' 2>&1 | $G"

block all
run "./gradlew --console=plain testDebugUnitTest 2>&1 | grep -E '^BUILD'"
run 'grep -ho "testsuite name=\"[a-zA-Z.]*\" tests=\"[0-9]*\" skipped=\"[0-9]*\" failures=\"[0-9]*\"" app/build/test-results/testDebugUnitTest/*.xml'
