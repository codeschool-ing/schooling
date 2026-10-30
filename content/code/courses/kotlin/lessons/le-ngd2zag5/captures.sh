#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of kotlin, as a script that
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

fresh kt/l03
MD=$HERE/declaring.md
kr Total.kt total
kc Hours.kt hours
MD=$HERE/single-expression.md
kr Format.kt format
kc NoElse.kt noelse
MD=$HERE/defaults-and-named.md
kr Describe.kt describe
kc Mixed.kt mixed
MD=$HERE/varargs.md
kr Vararg.kt vararg
kr VarargFirst.kt varargfirst
MD=$HERE/top-level-and-local.md
kr Report.kt report
block private
put "$MD" Planner.kt
put "$MD" Main.kt 1
run 'kotlinc Planner.kt Main.kt -include-runtime -d planner.jar'
block private-ok
put "$MD" Main.kt 2
run 'kotlinc Planner.kt Main.kt -include-runtime -d planner.jar && java -jar planner.jar'
MD=$HERE/unit-and-nothing.md
kr UnitNothing.kt unitnothing
kr Todo.kt todo
