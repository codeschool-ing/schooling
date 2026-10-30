#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of android-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The project is
# lesson 1's skeleton; every file this lesson adds or changes is lifted out of
# the lesson's own .md by ../../lab.sh, so the file built is the block the
# student copies.
#
# What is STAGED rather than typed:
#   - Summary.kt is written, compiled to show the refusal, and deleted, as the
#     section says;
#   - the Android CLI draws download progress with carriage returns, and the
#     commands shown filter it with `tr` and `grep`;
#   - the three PNGs the CLI rendered are copied off the machine to be embedded.
#
# Recorded on Ubuntu 24.04 with OpenJDK 21.0.12.1, Gradle 9.8.2, Android
# Gradle plugin 9.5.0, Android CLI 1.1.16717390 and Robolectric 4.17,
# TZ=America/Sao_Paulo, on 2026-10-30.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
SHOTS=${SHOTS:-/tmp/claude-0/-home-user-schooling/a10c356e-38bc-5069-a127-122e1cefc2dc/scratchpad/shots-a}
P=/var/lib/machines/android-lab/home/ana/w/l03/planner

project l03
put "$HERE/functions-that-draw.md" app/src/main/java/com/example/planner/data/Course.kt
put "$HERE/previews.md" app/src/main/java/com/example/planner/ui/CourseRow.kt
put "$HERE/previews.md" app/src/main/res/values/strings.xml
put "$HERE/slots.md" app/src/main/java/com/example/planner/ui/PlannerCard.kt
put "$HERE/side-effects.md" app/src/test/java/com/example/planner/RunsTest.kt
put "$HERE/side-effects.md" app/build.gradle.kts
quiet './gradlew --console=plain compileDebugKotlin'

block not-composable
put "$HERE/functions-that-draw.md" app/src/main/java/com/example/planner/ui/Summary.kt
run './gradlew --console=plain compileDebugKotlin 2>&1 | grep -E "^e:|^BUILD"'
rm "$P/app/src/main/java/com/example/planner/ui/Summary.kt"

block preview-list
run 'android preview list "?:app" 2>&1 | tr "\r" "\n" | grep -v Downloading'

block preview-render
run 'android preview render "?:app" --fqn com.example.planner.ui.CourseRowKt.CourseRowPreview --fqn com.example.planner.ui.CourseRowKt.CourseRowLargeTextPreview -o previews 2>&1 | tr "\r" "\n" | grep -v Downloading'
run 'file previews/com/example/planner/ui/CourseRowKt/*.png'
cp "$P/previews/com/example/planner/ui/CourseRowKt/CourseRowPreview_0.png" "$SHOTS/l03-row.png"
cp "$P/previews/com/example/planner/ui/CourseRowKt/CourseRowLargeTextPreview_0.png" "$SHOTS/l03-row-large.png"

block preview-card
run 'android preview render "?:app" --fqn com.example.planner.ui.PlannerCardKt.PlannerCardPreview -o previews 2>&1 | tr "\r" "\n" | grep -v Downloading'
cp "$P/previews/com/example/planner/ui/PlannerCardKt/PlannerCardPreview_0.png" "$SHOTS/l03-card.png"

block runs
run './gradlew --console=plain testDebugUnitTest --tests "*RunsTest" 2>&1 | grep -E "STANDARD_OUT|the (screen|list)|^BUILD"'
