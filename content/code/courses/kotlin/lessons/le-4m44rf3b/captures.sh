#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of kotlin, as a script that
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

fresh kt/l07
MD=$HERE/primary-constructor.md
kr Course.kt course
kr Session.kt session
MD=$HERE/properties.md
kr Goal.kt goal
MD=$HERE/init-blocks.md
kr Order.kt order
kc TooEarly.kt tooearly
kr Checked.kt checked
MD=$HERE/secondary-constructors.md
kr Secondary.kt secondary
kr Parse.kt parse
MD=$HERE/visibility.md
kc Tracker.kt tracker
kr TrackerOk.kt trackerok
MD=$HERE/lateinit.md
kr Late.kt late
