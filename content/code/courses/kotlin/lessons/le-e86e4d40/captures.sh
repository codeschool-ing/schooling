#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   (the captures of lessons 14 to 18, which build ~/kt/planner)
#   sudo bash captures.sh
#
# Every file is lifted out of this lesson's .md by ../../lab.sh, so the file
# built is the block the student copies.
#
# What is STAGED rather than typed:
#   - ~/kt/studyplan is emptied first, so a second recording starts where the
#     student does;
#   - the line added to app's Main.kt in "internal is visible inside one
#     module", and its removal, are made with sed, where the student edits
#     the file by hand;
#   - Maven Central is reached through the recording mirror lab.sh describes.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21, Gradle 9.8.2 and kotlinx-coroutines 1.11.0, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

at kt/planner
block props
run 'cat gradle/wrapper/gradle-wrapper.properties'
block version
run './gradlew --version'
block deps
run './gradlew -q dependencies --configuration runtimeClasspath'
block major
run 'javap -v build/classes/kotlin/main/HelloKt.class | grep major'
MD=$HERE/version-catalog.md
put "$MD" gradle/libs.versions.toml
put "$MD" build.gradle.kts
block catalog
run './gradlew -q run -Pmain=WeekModelKt'

fresh kt/studyplan
MD=$HERE/modules.md
block layout
run 'cp -r ../planner/gradle ../planner/gradlew ../planner/gradlew.bat .'
run 'find . -type f | sort'
for f in settings.gradle.kts build.gradle.kts core/build.gradle.kts core/src/main/kotlin/Week.kt \
         app/build.gradle.kts app/src/main/kotlin/Main.kt; do
  put "$MD" "$f"
done
block twomodules
run './gradlew :app:run'
MD=$HERE/internal.md
put "$MD" core/src/test/kotlin/WeekTest.kt
block coretest
run './gradlew -q :core:test && echo tests passed'
quiet 'sed -i "s/^    println(week.summary())$/    println(week.summary())\n    println(week.percent())/" app/src/main/kotlin/Main.kt'
block internal
run './gradlew -q :app:run 2>&1 | head -3'
quiet 'sed -i "/week.percent()/d" app/src/main/kotlin/Main.kt'
block install
run './gradlew -q :app:installDist'
run 'ls app/build/install/app/bin app/build/install/app/lib'
run 'app/build/install/app/bin/app'
