#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of kotlin, as a script that
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

fresh kt/l11
MD=$HERE/interfaces.md
kr Interfaces.kt interfaces
kc Broken.kt broken
MD=$HERE/inheritance.md
kc Final.kt final
kr Inheritance.kt inheritance
MD=$HERE/class-delegation.md
kr Delegation.kt delegation
MD=$HERE/property-delegation.md
kr Delegates.kt delegates
kr MapDelegate.kt mapdelegate
MD=$HERE/extension-functions.md
kr Extensions.kt extensions
kr Dispatch.kt dispatch
kr Shadow.kt shadow
MD=$HERE/extension-properties.md
kr ExtProps.kt extprops
kc ExtField.kt extfield
