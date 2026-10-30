#!/usr/bin/env bash
# The terminal session quoted in lesson 11 of ios-apps, as a script that
# produces it. The block of output starts with `##### curves`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Package.swift, Sources/Motion/Curve.swift and Sources/curves/main.swift are
# lifted out of curves.md by ../../lab.sh, so the files compiled are the
# blocks the student copies. Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
MD=$HERE/curves.md

fresh l11
for f in Package.swift Sources/Motion/Curve.swift Sources/curves/main.swift; do put "$MD" "$f"; done
block curves
run 'swift build'
run '.build/debug/curves'
