#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of kotlin, as a script that
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

fresh kt/l05
MD=$HERE/read-only-and-mutable.md
kr Lists.kt lists
kc AddToList.kt addtolist
kr View.kt view
kr Build.kt build
MD=$HERE/map-filter.md
kr MapFilter.kt mapfilter
MD=$HERE/aggregates.md
kr Aggregates.kt aggregates
kr Empty.kt empty
MD=$HERE/grouping.md
kr Grouping.kt grouping
MD=$HERE/fold-reduce.md
kr Fold.kt fold
kr Reduce.kt reduce
MD=$HERE/sequences.md
kr Lazy.kt lazy
kr Infinite.kt infinite
MD=$HERE/maps-and-sets.md
kr MapsSets.kt mapssets
