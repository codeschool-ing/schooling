#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   (sudo bash ../le-a3khgc0j/captures.sh, which builds ~/kt/planner)
#   sudo bash captures.sh
#
# Every file is lifted out of this lesson's .md by ../../lab.sh into the
# project lesson 14 built, so the file run is the block the student copies.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21, Gradle 9.8.2 and kotlinx-coroutines 1.11.0, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

at kt/planner
gr() { block "$2"; put "$MD" "src/main/kotlin/$1"; run "./gradlew -q run -Pmain=${1%.kt}Kt"; }
MD=$HERE/hot-and-cold.md
gr Hot.kt hot
MD=$HERE/stateflow.md
gr State.kt state
MD=$HERE/backing-property.md
gr Backing.kt backing
block backingwrite
put "$MD" src/main/kotlin/BackingWrite.kt
run './gradlew -q run -Pmain=BackingWriteKt 2>&1 | head -3'
quiet 'rm src/main/kotlin/BackingWrite.kt'
MD=$HERE/sharedflow.md
gr SharedEvents.kt shared
MD=$HERE/statein-sharein.md
gr ShareIn.kt sharein
MD=$HERE/state-holder.md
gr WeekModel.kt weekmodel
