#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of ios-apps, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Each program here is one file, lifted out of this lesson's .md by
# ../../lab.sh and run with `swift <file>`, so the file run is the block the
# student copies. Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh l03
put "$HERE/some-view.md" opaque.swift
put "$HERE/counting-bodies.md" bodies.swift
put "$HERE/builders.md" builder.swift
put "$HERE/conditional-views.md" branches.swift

block opaque
run 'swift opaque.swift; echo $?'
block bodies
run 'swift bodies.swift'
block builder
run 'swift builder.swift'
block branches
run 'swift branches.swift'
