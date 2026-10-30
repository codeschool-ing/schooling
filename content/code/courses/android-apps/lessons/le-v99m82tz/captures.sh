#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of android-apps, as a script that
# produces them, and the one screenshot. Every block of output starts with
# `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh [SHOTDIR]
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here is lifted out of this lesson's .md by ../../lab.sh, so the file built
# is the block the student copies. The PNG the screenshot test writes is
# copied to SHOTDIR and embedded in the-card.md as it came out.
#
# What is STAGED rather than typed:
#   - the project starts as lesson 1 section 05 leaves it (`project`), and
#     each section's files are added before its own block runs;
#   - nothing else. The system's dialog, the settings screen and the adb
#     commands of section 07 were not run: no device or emulator was
#     available. AskTwiceTest's stand-in for the dialog is in the lesson.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2, AGP 9.5.0,
# Robolectric 4.17 and Roborazzi 1.77.0, TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${1:-/tmp}
P=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner
tests() { run "./gradlew --console=plain ${2:-testDebugUnitTest} --tests '$1' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'"; }

block offer-test
project l20
MD=$HERE/asking.md
for f in app/build.gradle.kts app/src/main/AndroidManifest.xml app/src/main/res/values/strings.xml $P/ui/RemindersSetting.kt; do put "$MD" "$f"; done
put "$HERE/the-decision.md" $P/ui/ReminderPermission.kt
put "$HERE/the-card.md" $P/ui/ReminderCard.kt
put "$HERE/the-decision.md" $T/ui/OfferTest.kt
tests '*OfferTest'

block card-shot
put "$HERE/the-card.md" $T/ui/CardShotTest.kt
tests '*CardShotTest' recordRoborazziDebug
shot screenshots/reminder-offers.png "$SHOTS/l20-reminder-offers.png"

block ask-twice
put "$HERE/denied-twice.md" $T/ui/AskTwiceTest.kt
tests '*AskTwiceTest'
