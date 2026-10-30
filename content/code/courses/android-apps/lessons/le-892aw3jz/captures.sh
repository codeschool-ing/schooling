#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of android-apps, as a script that
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
#     and every file of section 03 is written before the first test runs.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, AGP 9.5.0,
# Kotlin 2.4.21, Room 2.8.5, Retrofit 3.0.0, OkHttp 5.5.1 and Robolectric
# 4.17 (Android 35), TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
D=app/src/main/java/com/example/planner/data
T=app/src/test/java/com/example/planner/data
TESTS='./gradlew --console=plain testDebugUnitTest'
R=$HERE/the-repository.md

project l16
put "$R" app/build.gradle.kts
put "$R" $D/Model.kt
put "$R" $D/Local.kt
put "$R" $D/Remote.kt
put "$R" $D/SessionRepository.kt

block refresh
put "$HERE/cache-and-refresh.md" $T/RefreshTest.kt
run "$TESTS --tests \"*RefreshTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD|^e: \""

block offline
put "$HERE/when-the-network-fails.md" $T/OfflineTest.kt
run "$TESTS --tests \"*OfflineTest\" 2>&1 | grep -E \"^    [a-z0-9]|PASSED|FAILED|^BUILD|^e: \""

block local-first
put "$HERE/local-first.md" $T/WriteTest.kt
run "$TESTS --tests \"*WriteTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD|^e: \""

block fakes
put "$HERE/testing-with-fakes.md" $T/Fakes.kt
put "$HERE/testing-with-fakes.md" $T/RepositoryWithFakesTest.kt
run "$TESTS --tests \"*RepositoryWithFakesTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD|^e: \""

block all-tests
run "$TESTS 2>&1 | grep -E \"PASSED|FAILED|^BUILD\""
