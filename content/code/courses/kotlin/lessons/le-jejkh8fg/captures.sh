#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of kotlin, as a script that
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

fresh kt/l10
MD=$HERE/object-declaration.md
kr Planner.kt planner
MD=$HERE/companion.md
kr Companion.kt companion
kc Direct.kt direct
block javap
run 'kotlinc Companion.kt -d classes'
run 'ls classes'
run 'javap -cp classes Session'
run "javap -cp classes 'Session\$Companion'"
MD=$HERE/const-and-jvm.md
block static
put "$MD" Static.kt
run 'kotlinc Static.kt -d static'
run 'javap -cp static Session'
MD=$HERE/object-expressions.md
kr Anonymous.kt anonymous
kr Shorter.kt shorter
MD=$HERE/data-object.md
kr DataObject.kt dataobject
MD=$HERE/singletons-cost.md
kr Shared.kt shared
kr Passed.kt passed
