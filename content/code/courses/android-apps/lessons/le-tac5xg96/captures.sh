#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The project is
# lesson 1's skeleton; every file added here is lifted out of this lesson's
# .md by ../../lab.sh, so the file built is the block the student copies.
#
# What is STAGED rather than typed:
#   - the project starts as a copy of lesson 1's, with its Gradle wrapper,
#     and every main-source file of the lesson is written before the first
#     test runs;
#   - the screenshot of section 05 is copied out of the build directory the
#     test wrote it to, and embedded in the section as a PNG.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, AGP 9.5.0,
# Kotlin 2.4.21, Coil 3.6.3, OkHttp 5.5.1, Robolectric 4.17 (Android 35) and
# Roborazzi 1.77.0, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
M=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner
TESTS='./gradlew --console=plain testDebugUnitTest'
SHOTS=${SHOTS:-/tmp/claude-0/-home-user-schooling/a10c356e-38bc-5069-a127-122e1cefc2dc/scratchpad/shots}

project l17
put "$HERE/async-image.md" app/build.gradle.kts
put "$HERE/async-image.md" app/src/main/AndroidManifest.xml
put "$HERE/async-image.md" $M/ui/CourseCard.kt
put "$HERE/caches.md" $M/PlannerApp.kt
put "$HERE/lists.md" $M/ui/CourseList.kt
put "$HERE/lists.md" $M/data/Model.kt

block bitmap-memory
put "$HERE/bitmap-memory.md" $T/BitmapMemoryTest.kt
run "$TESTS --tests \"*BitmapMemoryTest\" 2>&1 | grep -E \"^    [a-z]|PASSED|FAILED|^BUILD|^e: \""

block caches
put "$HERE/caches.md" $T/CacheTest.kt
run "$TESTS --tests \"*CacheTest\" 2>&1 | grep -E \"^    [a-z]|PASSED|FAILED|^BUILD|^e: \""

block states
put "$HERE/states.md" $T/StatesScreenshotTest.kt
run './gradlew --console=plain recordRoborazziDebug --tests "*StatesScreenshotTest" 2>&1 | grep -E "PASSED|FAILED|^BUILD|^e: "'
run 'ls -l app/build/outputs/roborazzi/'
shot build/outputs/roborazzi/course-card-states.png "$SHOTS/l17-states.png"

block list-memory
put "$HERE/lists.md" $T/ListMemoryTest.kt
run "$TESTS --tests \"*ListMemoryTest\" 2>&1 | grep -E \"^    [a-z]|PASSED|FAILED|^BUILD|^e: \""

block all-tests
run "$TESTS 2>&1 | grep -E \"PASSED|FAILED|^BUILD\""
