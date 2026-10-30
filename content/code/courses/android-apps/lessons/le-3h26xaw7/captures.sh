#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of android-apps, as a script that
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
#     each section's files are added before its own block runs;
#   - each test is run on its own, with --tests, so the lines come out in the
#     order the lesson reads them rather than the order Gradle picks.
#   - nothing else. The shade, the dialog and the adb commands of section 07
#     were not run: no device or emulator was available.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21, Gradle 9.8.2, AGP 9.5.0 and
# Robolectric 4.17 (Android 15 and Android 12 images), TZ=America/Sao_Paulo,
# on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
P=app/src/main/java/com/example/planner
T=app/src/test/java/com/example/planner
tests() { run "./gradlew --console=plain testDebugUnitTest --tests '$1' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'"; }

block channel-test
project l19
MD=$HERE/channels.md
for f in app/build.gradle.kts app/src/main/res/values/strings.xml $P/notify/Channels.kt $P/PlannerApp.kt app/src/main/AndroidManifest.xml $T/notify/ChannelTest.kt; do put "$MD" "$f"; done
tests '*ChannelTest'

block reminder-test
MD=$HERE/building-one.md
for f in app/src/main/res/drawable/ic_notification.xml $P/notify/Reminders.kt $T/notify/ReminderTest.kt; do put "$MD" "$f"; done
tests '*ReminderTest'

block permission-test
put "$HERE/the-permission.md" $T/notify/PermissionTest.kt
for t in notGranted granted grantedButTurnedOff beforeAndroid13 theCheckAloneOnAndroid12 notifyWithNoCheckAtAll; do
  run "./gradlew --console=plain testDebugUnitTest --tests '*PermissionTest.$t' 2>&1 | grep '^    '"
done

block replace-test
put "$HERE/the-tap.md" $T/notify/ReplaceTest.kt
tests '*ReplaceTest'
