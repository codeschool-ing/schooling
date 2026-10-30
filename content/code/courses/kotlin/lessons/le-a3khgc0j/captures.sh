#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every file of the project is lifted out of this lesson's .md by
# ../../lab.sh, so the file built is the block the student copies.
#
# What is STAGED rather than typed:
#   - before the first build, ~/.gradle is emptied of everything Gradle
#     downloads (the wrapper's distribution, the caches, the daemons) and any
#     daemon still running is stopped, so the first ./gradlew is a first run;
#   - Maven Central is reached through the recording mirror lab.sh
#     describes; the student's build reaches Maven Central itself;
#   - the two failures run on copies of the project, ~/kt/broken-version and
#     ~/kt/broken-toolchain, made with cp and edited with sed as shown.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21, Gradle 9.8.2 and kotlinx-coroutines 1.11.0, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

at .
quiet 'gradle --stop; rm -rf ~/.gradle/caches ~/.gradle/wrapper ~/.gradle/daemon ~/.gradle/native ~/.gradle/.tmp ~/kt/broken-version ~/kt/broken-toolchain'
fresh kt/planner
MD=$HERE/gradle-project.md
put "$MD" settings.gradle.kts
put "$MD" build.gradle.kts
put "$MD" src/main/kotlin/Hello.kt
block wrapper
run 'gradle wrapper'
run 'ls'
run './gradlew run'
block second
run './gradlew -q run'

block fail-version
at kt
run 'cp -r planner broken-version && cd broken-version && sed -i "s/1.11.0/1.99.0/" build.gradle.kts && ./gradlew -q run 2>&1 | head -9'
block fail-toolchain
run 'cp -r planner broken-toolchain && cd broken-toolchain && sed -i "s/jvmToolchain(21)/jvmToolchain(17)/" build.gradle.kts && ./gradlew -q run 2>&1 | head -8'
quiet 'cd ~/kt/broken-version && ./gradlew --stop; rm -rf ~/kt/broken-version ~/kt/broken-toolchain'
at kt/planner

# gr FILE BLOCK: put src/main/kotlin/FILE out of $MD and run its main
gr() { block "$2"; put "$MD" "src/main/kotlin/$1"; run "./gradlew -q run -Pmain=${1%.kt}Kt"; }
MD=$HERE/suspend.md
gr Suspend.kt suspend
gr NotSuspend.kt notsuspend
quiet 'rm src/main/kotlin/NotSuspend.kt'
MD=$HERE/launch.md
gr Launch.kt launch
MD=$HERE/async.md
gr Async.kt async
MD=$HERE/dispatchers.md
gr Dispatch.kt dispatch
MD=$HERE/threads-vs-coroutines.md
gr Many.kt many
