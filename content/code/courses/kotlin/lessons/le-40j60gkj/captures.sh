#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .kt file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1 and Kotlin
# 2.4.21, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh kt/l09
MD=$HERE/when-expression.md
kr When.kt when
kr WhenIs.kt whenis
MD=$HERE/enums.md
kr Enums.kt enums
kc EnumAdded.kt enumadded
MD=$HERE/sealed-hierarchy.md
kr Sealed.kt sealed
MD=$HERE/exhaustive.md
kc Skipped.kt skipped
kr SkippedElse.kt skippedelse
MD=$HERE/sealed-interfaces.md
kr SealedInterface.kt sealedinterface
MD=$HERE/modelling-state.md
kr WeekState.kt weekstate
