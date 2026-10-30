#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   (the captures of lessons 14 to 19, which build ~/kt/planner)
#   sudo bash captures.sh
#
# Every file is lifted out of this lesson's .md by ../../lab.sh, so the file
# built is the block the student copies.
#
# What is STAGED rather than typed:
#   - ~/kt/server, ~/kt/shared and ~/kt/scripts are emptied first, and so are
#     the Node.js and Yarn that Gradle downloads into ~/.gradle and the cache
#     of compiled scripts in ~/.cache, so each first run is a first run;
#   - the server runs in the background with its output in server.log, and
#     that output is printed under the command that started it: the student
#     starts it in one terminal and sends requests from a second, and this
#     script has one terminal. It is stopped with pkill where the student
#     presses Ctrl+C;
#   - Maven Central, Node.js and the npm registry are reached through the
#     recording proxy lab.sh describes.
#
# Not recorded: the native target's build. The Kotlin/Native compiler comes
# from Maven Central, but the C toolchain it downloads on the first build is
# on download.jetbrains.com, which the recording machine cannot reach. The
# lesson says so where the transcript would be.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21, Gradle 9.8.2, Ktor 3.6.1 and kotlinx-coroutines 1.11.0,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

copy_wrapper='mkdir -p gradle && cp -r ../planner/gradle/wrapper gradle/ && cp ../planner/gradlew ../planner/gradlew.bat .'

fresh kt/server
quiet "$copy_wrapper"
MD=$HERE/server.md
for f in settings.gradle.kts gradle/libs.versions.toml build.gradle.kts src/main/kotlin/Server.kt; do
  put "$MD" "$f"
done
block start
run './gradlew -q installDist'
quiet 'nohup build/install/server/bin/server > server.log 2>&1 &'
sleep 8
_prompt kt/server 'build/install/server/bin/server'
bash "$LAB_SH" exec kt/server 'cat server.log' | _strip
block hello
run "curl -s -w '\n' localhost:8080/"
run "curl -s -w '\n' localhost:8080/sessions"
block post
run "curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{\"course\":\"android-apps\",\"minutes\":30}'"
run "curl -s -w '\n' localhost:8080/sessions"
block refused
run "curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{\"course\":\"kotlin\",\"minutes\":0}'"
run "curl -s -i -w '\n' localhost:8080/sessions -H 'Content-Type: application/json' -d '{\"course\":\"kotlin\"}'"
quiet 'pkill -f "[s]tudyplan.server.ServerKt"'
MD=$HERE/server-test.md
put "$MD" src/test/kotlin/ServerTest.kt
block servertest
run './gradlew -q test && echo tests passed'

fresh kt/shared
quiet "$copy_wrapper"
quiet 'rm -rf ~/.gradle/nodejs ~/.gradle/yarn'
MD=$HERE/multiplatform.md
for f in settings.gradle.kts build.gradle.kts src/commonMain/kotlin/Week.kt src/commonMain/kotlin/Main.kt \
         src/jvmMain/kotlin/Platform.jvm.kt src/jsMain/kotlin/Platform.js.kt; do
  put "$MD" "$f"
done
block jvmrun
run './gradlew -q jvmRun'
block jsrun
run './gradlew -q jsNodeDevelopmentRun'

fresh kt/scripts
quiet 'rm -rf ~/.cache/main.kts.compiled.cache'
MD=$HERE/scripting.md
block weekfile
run 'cp ../planner/week.txt .'
run 'cat week.txt'
put "$MD" total.main.kts
block script
run 'time kotlin total.main.kts'
run 'chmod +x total.main.kts'
run 'time ./total.main.kts week.txt'
