#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of android-apps, as a script that
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
#   - the project starts as a copy of lesson 1's, with its Gradle wrapper;
#   - the files are written in the order the sections show them; where a
#     section replaces a file (SessionDto.kt in section 05), the capture
#     writes the later block over the earlier one, as the student does.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, AGP 9.5.0,
# Kotlin 2.4.21, kotlinx.serialization 1.12.0, Moshi 1.15.2, KSP 2.3.12,
# Retrofit 3.0.0 and OkHttp 5.5.1, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
D=app/src/main/java/com/example/planner/data
T=app/src/test/java/com/example/planner/data
TESTS='./gradlew --console=plain testDebugUnitTest'
show() { grep -E "STANDARD_OUT|PASSED|FAILED|^    |^BUILD|^e: |tests completed"; }

project l14
put "$HERE/the-wire.md" $D/Model.kt
put "$HERE/kotlinx-serialization.md" app/build.gradle.kts
put "$HERE/kotlinx-serialization.md" $D/SessionDto.kt
put "$HERE/kotlinx-serialization.md" $T/SessionJsonTest.kt

block round-trip
run "$TESTS 2>&1 | grep -E \"STANDARD_OUT|PASSED|FAILED|^    |^BUILD\""

block serializer-class
run 'find app/build/intermediates -name "SessionDto*.class" | sed "s|.*/classes/||" | sort'

block no-plugin
run 'sed -i "/kotlin.serialization/d" app/build.gradle.kts'
run "$TESTS 2>&1 | grep -E \"PASSED|FAILED|Exception|^BUILD\""
run 'grep -o "message=\"[^\"]*\"" app/build/test-results/testDebugUnitTest/*SessionJsonTest.xml'
put "$HERE/kotlinx-serialization.md" app/build.gradle.kts

block server-changes
put "$HERE/when-the-server-changes.md" $T/ServerChangesTest.kt
put "$HERE/when-the-server-changes.md" $D/PlannerJson.kt
run "$TESTS --tests \"*ServerChangesTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD\""

block no-serializer
put "$HERE/dates.md" $D/SessionDto.kt 1
run "$TESTS 2>&1 | grep -E \"^e: |^BUILD\""

block dates
put "$HERE/dates.md" $D/LocalDateSerializer.kt
put "$HERE/dates.md" $D/SessionDto.kt 2
put "$HERE/dates.md" $D/Mapping.kt
put "$HERE/dates.md" $T/DatesTest.kt
run "$TESTS --tests \"*DatesTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD\""

block moshi
put "$HERE/moshi.md" $D/SessionJson.kt
put "$HERE/moshi.md" $T/MoshiTest.kt
run "$TESTS --tests \"*MoshiTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD\""

block moshi-generated
run 'find app/build/generated/ksp -name "*.kt"'
run 'grep -nE "class SessionJsonJsonAdapter|options: JsonReader.Options|missingProperty" app/build/generated/ksp/debug/kotlin/com/example/planner/data/SessionJsonJsonAdapter.kt'

block not-mocked
put "$HERE/the-converter.md" $D/PlannerApi.kt
put "$HERE/the-converter.md" $T/PlannerApiTest.kt
run "$TESTS --tests \"*PlannerApiTest\" 2>&1 | grep -E \"^    [a-zA-Z]|PASSED|FAILED|^BUILD\""

block converter
put "$HERE/the-converter.md" app/build.gradle.kts
run "$TESTS --tests \"*PlannerApiTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD\""

block all-tests
run "$TESTS 2>&1 | grep -E \"PASSED|FAILED|^BUILD\""
