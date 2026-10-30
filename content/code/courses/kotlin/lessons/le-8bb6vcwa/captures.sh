#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of kotlin, as a script that
# produces them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# Every .kt file compiled here is lifted out of this lesson's .md by
# ../../lab.sh, so the file compiled is the block the student copies.
# Nothing is staged: STUDY_HOME is set on the command line where the lesson
# shows it set.
#
# Recorded on Ubuntu 24.04 with openjdk-21-jdk-headless 21.0.12.1 and Kotlin
# 2.4.21, TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"

fresh kt/l02
MD=$HERE/two-types.md
kr Nulls.kt nulls
kc NullAssign.kt nullassign
kc NoteLength.kt notelength
MD=$HERE/safe-call.md
kr SafeCall.kt safecall
MD=$HERE/elvis.md
kr Elvis.kt elvis
MD=$HERE/smart-casts.md
kr SmartCast.kt smartcast
kc Draft.kt draft
kr DraftFixed.kt draftfixed
MD=$HERE/double-bang.md
kr Bang.kt bang
kr NoBang.kt nobang
MD=$HERE/platform-types.md
block platform
put "$MD" Platform.kt
run 'kotlinc Platform.kt -include-runtime -d platform.jar'
run 'STUDY_HOME=/home/ana/study java -jar platform.jar'
run 'java -jar platform.jar'
block platformfixed
put "$MD" PlatformFixed.kt
run 'kotlinc PlatformFixed.kt -include-runtime -d platformfixed.jar'
run 'STUDY_HOME=/home/ana/study java -jar platformfixed.jar'
run 'java -jar platformfixed.jar'
block platformstrict
put "$MD" PlatformStrict.kt
run 'kotlinc PlatformStrict.kt -include-runtime -d platformstrict.jar && java -jar platformstrict.jar'
