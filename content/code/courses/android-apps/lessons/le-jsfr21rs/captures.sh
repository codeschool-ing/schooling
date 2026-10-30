#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file built
# here, app/build.gradle.kts included, is lifted out of this lesson's .md
# files by ../../lab.sh.
#
# What is STAGED rather than typed:
#   - the project is lesson 1's skeleton, as lesson 1 section 05 leaves it,
#     with section 02's build file written over the skeleton's;
#   - each block runs one test class with `--tests`, and reads what the tests
#     printed out of the XML result Gradle writes for each class. JUnit runs
#     BackStackTest's four methods in an order of its own, so the two blocks
#     that quote it pick their lines out by label.
#
# Not run, and said so in the lesson: the predictive back animation and
# opening a deep link, which need a device.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, the Android
# Gradle plugin 9.5.0, Navigation 2.10.2, Robolectric 4.17,
# TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
T=app/src/test/java/com/example/planner
M=app/src/main/java/com/example/planner
R=app/build/test-results/testDebugUnitTest
F() { echo "$R/TEST-com.example.planner.$1.xml"; }

project l09
put "$HERE/nav-host.md" app/build.gradle.kts
put "$HERE/nav-host.md" $M/Routes.kt
put "$HERE/nav-host.md" $M/Screens.kt
put "$HERE/nav-host.md" $M/PlannerNavHost.kt
put "$HERE/back-stack.md" $T/NavigationTest.kt
put "$HERE/pop-up-to.md" $T/BackStackTest.kt
put "$HERE/system-back.md" $T/SystemBackTest.kt
quiet './gradlew --console=plain assembleDebug'

block stack
run "./gradlew --console=plain testDebugUnitTest --tests '*.NavigationTest' 2>&1 | grep -E '^BUILD|FAILED'"
run "grep -h -e 'start ' -e '^tap ' $(F NavigationTest) | sed 's/.*CDATA\\[//'"

block arguments
run "grep -h -e 'tap Kotlin' -e 'argument' $(F NavigationTest)"

block double
run "./gradlew --console=plain testDebugUnitTest --tests '*.BackStackTest' 2>&1 | grep -E '^BUILD|FAILED'"
run "grep -h 'navigate twice' $(F BackStackTest) | sed 's/.*CDATA\[//'; grep -h 'launchSingleTop' $(F BackStackTest) | sed 's/.*CDATA\[//'"

block popping
run "grep -h 'navigate(Courses)' $(F BackStackTest) | sed 's/.*CDATA\[//'; grep -h 'popUpTo inclusive' $(F BackStackTest) | sed 's/.*CDATA\[//'"

block system-back
run "./gradlew --console=plain testDebugUnitTest --tests '*.SystemBackTest' 2>&1 | grep -E '^BUILD|FAILED'"
run "grep -h 'finishing' $(F SystemBackTest) | sed 's/.*CDATA\[//'"
