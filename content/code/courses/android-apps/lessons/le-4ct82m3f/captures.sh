#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of android-apps, as a script that
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
# What is STAGED rather than typed: nothing beyond lab.sh's own list. Every
# server in these transcripts is a MockWebServer started by the test itself
# on 127.0.0.1, at a port the system chose; nothing leaves the machine.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2, AGP 9.5.0,
# Retrofit 3.0.0 and OkHttp 5.5.1, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
R=app/src/main/java/com/example/planner/data/remote
T=app/src/test/java/com/example/planner/data/remote
G='grep -E "^(BUILD|[0-9]+ actionable)|PASSED|FAILED|^    [a-zA-Z0-9]"'
M=app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml

project l13
put "$HERE/the-api.md" app/build.gradle.kts
put "$HERE/the-api.md" $R/PlannerApi.kt
put "$HERE/the-api.md" $R/Network.kt
put "$HERE/errors.md" $R/ApiResult.kt
put "$HERE/timeouts-and-retries.md" $R/RetryInterceptor.kt
put "$HERE/interceptors.md" $R/AuthInterceptor.kt
put "$HERE/first-call.md" $T/PlannerApiTest.kt
put "$HERE/errors.md" $T/ApiResultTest.kt
put "$HERE/timeouts-and-retries.md" $T/TimeoutTest.kt
put "$HERE/timeouts-and-retries.md" $T/RetryTest.kt
put "$HERE/interceptors.md" $T/LoggingTest.kt
quiet './gradlew --console=plain assembleDebug'

block first
run "./gradlew --console=plain testDebugUnitTest --tests '*PlannerApiTest' 2>&1 | $G"

block errors
run "./gradlew --console=plain testDebugUnitTest --tests '*ApiResultTest' 2>&1 | $G"

block timeout
run "./gradlew --console=plain testDebugUnitTest --tests '*TimeoutTest' 2>&1 | $G"

block retry
run "./gradlew --console=plain testDebugUnitTest --tests '*RetryTest' 2>&1 | $G"

block logging
run "./gradlew --console=plain testDebugUnitTest --tests '*LoggingTest' 2>&1 | $G"

block no-internet
run "grep -A2 '^uses-permission#android.permission.INTERNET' app/build/outputs/logs/manifest-merger-debug-report.txt"

block with-internet
put "$HERE/the-manifest.md" app/src/main/AndroidManifest.xml
put "$HERE/the-manifest.md" app/src/debug/res/xml/network_security_config.xml
put "$HERE/the-manifest.md" app/src/debug/AndroidManifest.xml
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"'
run "grep -E 'android.permission.INTERNET|networkSecurityConfig' $M"
