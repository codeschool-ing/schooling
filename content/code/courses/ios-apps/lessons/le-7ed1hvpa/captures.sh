#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Each program is one file, lifted out of this lesson's .md by ../../lab.sh
# and run with `swift <file>`, so the file run is the block the student
# copies. Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh l05
put "$HERE/the-if-trap.md" iftrap.swift
put "$HERE/wrapper-model.md" wrappers.swift
block iftrap
run 'swift iftrap.swift'
block wrappers
run 'swift wrappers.swift'
