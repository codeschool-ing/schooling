#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of android-apps, as a script that
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
#   - where a section replaces a file (PlannerDatabase.kt in sections 04, 05
#     and 07, Entities.kt in section 07), the capture writes the later block
#     over the earlier one, as the student does.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, AGP 9.5.0,
# Kotlin 2.4.21, KSP 2.3.12, Room 2.8.5 and Robolectric 4.17 (Android 35),
# TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
D=app/src/main/java/com/example/planner/data
T=app/src/test/java/com/example/planner/data
TESTS='./gradlew --console=plain testDebugUnitTest'

project l15
put "$HERE/why-room.md" app/build.gradle.kts
put "$HERE/why-room.md" $D/Model.kt
put "$HERE/entities.md" $D/Entities.kt

block no-converter
put "$HERE/type-converters.md" $D/PlannerDatabase.kt 1
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^e: |^BUILD"'

block converter-build
put "$HERE/type-converters.md" $D/Converters.kt
put "$HERE/type-converters.md" $D/PlannerDatabase.kt 2
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^(w|e): |^BUILD"'

block schema-json
run 'find app/schemas -type f'
run 'grep -o "\"createSql\": \"CREATE TABLE[^\"]*course_id[^\"]*" app/schemas/com.example.planner.data.PlannerDatabase/1.json'

block typo
put "$HERE/daos.md" $D/Daos.kt
put "$HERE/daos.md" $D/PlannerDatabase.kt
run 'sed -i "s/FROM sessions WHERE course_id/FROM session WHERE course_id/" app/src/main/java/com/example/planner/data/Daos.kt'
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^e: |^BUILD"'
run 'sed -i "s/FROM session WHERE course_id/FROM sessions WHERE course_id/" app/src/main/java/com/example/planner/data/Daos.kt'

block dao-test
put "$HERE/daos.md" $T/DaoTest.kt
run "$TESTS --tests \"*DaoTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD\""

block flow-test
put "$HERE/flow-queries.md" $T/FlowTest.kt
run "$TESTS --tests \"*FlowTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD\""

block schemas
put "$HERE/migrations.md" $D/Entities.kt
put "$HERE/migrations.md" $D/PlannerDatabase.kt
run './gradlew --console=plain assembleDebug 2>&1 | grep -E "^(w|e): |^BUILD"'
run 'find app/schemas -type f | sort'
run 'grep -o "\"createSql\": \"CREATE TABLE[^\"]*course_id[^\"]*" app/schemas/com.example.planner.data.PlannerDatabase/2.json'

block migration-test
put "$HERE/migrations.md" $T/MigrationTest.kt
run "$TESTS --tests \"*MigrationTest\" 2>&1 | grep -E \"^    |PASSED|FAILED|^BUILD\""

block all-tests
run "$TESTS 2>&1 | grep -E \"PASSED|FAILED|^BUILD\""
