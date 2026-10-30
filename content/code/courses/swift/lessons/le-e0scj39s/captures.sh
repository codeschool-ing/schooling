#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l08
MD=$HERE/protocols.md
sr Describable.swift describable
MD=$HERE/conformance.md
se Missing.swift missing
sr Conform.swift conform
MD=$HERE/extensions.md
sr Hours.swift hours
se Stored.swift stored
sr Retro.swift retro
MD=$HERE/defaults.md
sr Defaults.swift defaults
MD=$HERE/standard-protocols.md
sr Session.swift session
block noteref
put "$MD" NoteRef.swift
run 'swiftc NoteRef.swift -o noteref 2>&1 | head -13'
run 'swiftc NoteRef.swift -o noteref 2>&1 | wc -l'
MD=$HERE/dispatch.md
sr Dispatch.swift dispatch
