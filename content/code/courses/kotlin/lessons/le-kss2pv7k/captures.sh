#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of kotlin, as a script that
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

fresh kt/l12
MD=$HERE/generic-functions.md
kr Generic.kt generic
kc Explicit.kt explicit
MD=$HERE/classes-and-bounds.md
kr Ranked.kt ranked
kc Unranked.kt unranked
MD=$HERE/variance-out.md
kc Variance.kt variance
kc Out.kt out
MD=$HERE/variance-in.md
kr In.kt in
MD=$HERE/star-projection.md
kr Star.kt star
kc StarAdd.kt staradd
MD=$HERE/erasure-and-reified.md
kc Erased.kt erased
kr Reified.kt reified
