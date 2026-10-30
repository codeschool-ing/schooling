#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of kotlin, as a script that
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

fresh kt/l08
MD=$HERE/what-data-generates.md
kr Data.kt data
kr Plain.kt plain
MD=$HERE/equality.md
kr Identity.kt identity
kr Interned.kt interned
MD=$HERE/copy.md
kr Copy.kt copy
kr Shallow.kt shallow
MD=$HERE/destructuring.md
kr Destructure.kt destructure
kr Swap.kt swap
MD=$HERE/data-limits.md
kr Body.kt body
kr ArrayProp.kt arrayprop
MD=$HERE/value-classes.md
kr Minutes.kt minutes
kc MinutesWrong.kt minuteswrong
