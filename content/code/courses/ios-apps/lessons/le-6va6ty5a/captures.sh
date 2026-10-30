#!/usr/bin/env bash
# The terminal session quoted in lesson 4 of ios-apps, as a script that
# produces it. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# layout.swift is lifted out of layout-model.md by ../../lab.sh and run with
# `swift layout.swift`, so the file run is the block the student copies.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh l04
put "$HERE/layout-model.md" layout.swift
block layout
run 'swift layout.swift'
