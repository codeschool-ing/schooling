#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies; the
# annotated example is joined part by part, as the copy button joins it.
# Nothing is staged. `unordered` runs one program three times on purpose:
# the order it prints changes between processes, and the lesson says so.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l04
MD=$HERE/arrays.md
sr Arrays.swift arrays
block outofrange
put "$MD" OutOfRange.swift
run 'swiftc OutOfRange.swift -o outofrange'
run './outofrange 2>&1 | head -3'
se LetArray.swift letarray
MD=$HERE/dictionaries-sets.md
sr Dictionaries.swift dictionaries
block unordered
put "$MD" Unordered.swift
run 'swift Unordered.swift'
run 'swift Unordered.swift'
run 'swift Unordered.swift'
sr Sets.swift sets
MD=$HERE/map-filter-reduce.md
sr Transform.swift transform
sr Reduce.swift reduce
MD=$HERE/sorting-grouping.md
sr Sorting.swift sorting
sr Grouping.swift grouping
MD=$HERE/strings.md
sr Strings.swift strings
se StringIndex.swift stringindex
sr StringIndexFixed.swift stringindexfixed
MD=$HERE/lazy.md
sr Lazy.swift lazy
sr Endless.swift endless
