#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here is lifted out of this lesson's .md files by ../../lab.sh. The
# screenshots the tests record are copied out to $SHOTS and embedded in the
# lesson as they were written.
#
# What is STAGED rather than typed:
#   - the project is lesson 1's skeleton, as lesson 1 section 05 leaves it;
#   - each block runs one test class with `--tests`, and reads what the tests
#     printed out of the XML result Gradle writes for each class.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, the Android
# Gradle plugin 9.5.0, Compose BOM 2026.09.00, Robolectric 4.17 and Roborazzi
# 1.77.0, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/android-apps-shots/l08}
mkdir -p "$SHOTS"
T=app/src/test/java/com/example/planner
M=app/src/main/java/com/example/planner
R=app/build/test-results/testDebugUnitTest
said() { run "grep -h -e '$2' $R/TEST-com.example.planner.$1.xml | sed 's/.*CDATA\\[//'"; }

project l08
put "$HERE/keys.md" $M/data/StudySession.kt
put "$HERE/keys.md" $M/ui/SessionItem.kt
put "$HERE/sections.md" $M/ui/SessionList.kt
put "$HERE/loading-more.md" $M/data/SessionPager.kt
put "$HERE/loading-more.md" $M/ui/EndlessList.kt
put "$HERE/why-lazy.md" $T/LazinessTest.kt
put "$HERE/keys.md" $T/KeysTest.kt
put "$HERE/sections.md" $T/SessionListTest.kt
put "$HERE/loading-more.md" $T/EndlessListTest.kt
quiet './gradlew --console=plain assembleDebug'

block laziness
run "./gradlew --console=plain testDebugUnitTest --tests '*.LazinessTest' 2>&1 | grep -E '^BUILD|FAILED'"
said LazinessTest 'composed'

block keys
run "./gradlew --console=plain testDebugUnitTest --tests '*.KeysTest' 2>&1 | grep -E '^BUILD|FAILED'"
said KeysTest 'keys, the'

block record-list
run "./gradlew --console=plain recordRoborazziDebug --tests '*.SessionListTest' 2>&1 | grep -E '^BUILD|FAILED'"
run 'ls app/shots'
shot shots/list-top.png "$SHOTS/list-top.png"
shot shots/list-scrolled.png "$SHOTS/list-scrolled.png"

block scrolled
said SessionListTest 'items\|visible'

block endless
run "./gradlew --console=plain testDebugUnitTest --tests '*.EndlessListTest' 2>&1 | grep -E '^BUILD|FAILED'"
said EndlessListTest 'loaded'
