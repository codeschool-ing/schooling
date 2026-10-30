#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .kt file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged: the programs that read week.txt write it first.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1 and Kotlin
# 2.4.21, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh kt/l13
MD=$HERE/throwing.md
kr Throw.kt throw
MD=$HERE/try-catch.md
kr TryExpr.kt tryexpr
kr TooBroad.kt toobroad
MD=$HERE/use.md
kr Use.kt use
kr Files.kt files
MD=$HERE/require-check.md
kr Guards.kt guards
MD=$HERE/result-type.md
kr ResultDemo.kt result
kr CatchesAll.kt catchesall
MD=$HERE/choosing.md
kr Planner.kt planner
