#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   (sudo bash ../le-a3khgc0j/captures.sh, which builds ~/kt/planner)
#   sudo bash captures.sh
#
# Every file is lifted out of this lesson's .md by ../../lab.sh into the
# project lesson 14 built, so the file run is the block the student copies.
# Nothing is staged; Maven Central is reached through the recording mirror
# lab.sh describes.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1, Kotlin
# 2.4.21, Gradle 9.8.2 and kotlinx-coroutines 1.11.0, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

at kt/planner
gr() { block "$2"; put "$MD" "src/main/kotlin/$1"; run "./gradlew -q run -Pmain=${1%.kt}Kt"; }
MD=$HERE/scopes.md
gr Scope.kt scope
MD=$HERE/cancellation.md
gr Cancel.kt cancel
MD=$HERE/failure.md
gr Failure.kt failure
MD=$HERE/supervisor.md
gr Supervisor.kt supervisor
MD=$HERE/timeouts.md
gr Timeout.kt timeout
MD=$HERE/pitfalls.md
gr Swallow.kt swallow
gr Global.kt global
