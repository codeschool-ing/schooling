#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of kotlin, as a script that
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

fresh kt/l06
MD=$HERE/receiver-or-argument.md
kr Scope.kt scope
MD=$HERE/let.md
kr Let.kt let
kr LetChain.kt letchain
MD=$HERE/apply.md
kr Apply.kt apply
MD=$HERE/also.md
kr Also.kt also
MD=$HERE/run-and-with.md
kr RunWith.kt runwith
MD=$HERE/choosing.md
kr Nested.kt nested
