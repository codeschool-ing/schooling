#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here is lifted out of this lesson's .md by ../../lab.sh, so the file built
# is the block the student copies.
#
# What is STAGED rather than typed:
#   - the project starts as lesson 1 section 05 leaves it (`project`), and
#     each section's files are added before its own block runs, in the order
#     the lesson shows them;
#   - nothing else: every test runs WorkManager inside Robolectric on the JVM,
#     and the phone-only behaviour of section 07 was not run.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2, AGP 9.5.0 and
# WorkManager 2.12.0, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
P=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner
tests() { run "./gradlew --console=plain testDebugUnitTest --tests '$1' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'"; }

block worker-test
project l18
MD=$HERE/a-worker.md
for f in app/build.gradle.kts $P/data/Uploader.kt $P/work/SyncWorker.kt $P/work/PlannerWorkerFactory.kt $T/work/SyncWorkerTest.kt; do put "$MD" "$f"; done
tests '*SyncWorkerTest'

block schedule-test
MD=$HERE/constraints-and-periods.md
for f in $P/work/Sync.kt $T/work/ScheduleTest.kt; do put "$MD" "$f"; done
tests '*ScheduleTest.waits*'
tests '*ScheduleTest.keep*'

block floor
tests '*ScheduleTest.fifteen*'

block chain-test
MD=$HERE/chains.md
for f in $P/work/SummaryWorker.kt $T/work/ChainTest.kt; do put "$MD" "$f"; done
tests '*ChainTest'

block manifest
MD=$HERE/the-application.md
for f in $P/PlannerApp.kt app/src/main/AndroidManifest.xml; do put "$MD" "$f"; done
run './gradlew --console=plain assembleDebug 2>&1 | grep -E -A1 "Warning:|^BUILD"'
run 'grep -c WorkManagerInitializer app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml'
run 'find ~/.gradle/caches -path "*work-runtime-2.12.0*" -name AndroidManifest.xml -exec grep -c WorkManagerInitializer {} \;'
run 'grep -o "uses-permission android:name=\"[^\"]*\"" app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml'
