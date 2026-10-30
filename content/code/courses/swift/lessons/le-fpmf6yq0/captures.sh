#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of swift, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .swift file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies; the
# annotated Computed.swift is its parts joined as the copy button joins them.
# Nothing is staged.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh sw/l06
MD=$HERE/stored.md
sr Stored.swift stored
se Course.swift course
MD=$HERE/computed.md
sr Computed.swift computed
se GetOnly.swift getonly
MD=$HERE/observers.md
sr Observers.swift observers
MD=$HERE/lazy.md
sr Lazy.swift lazy
se LazyLet.swift lazylet
MD=$HERE/static.md
sr Static.swift static
se StaticSelf.swift staticself
MD=$HERE/initialisers.md
se Unset.swift unset
sr Extra.swift extra
sr Failable.swift failable
