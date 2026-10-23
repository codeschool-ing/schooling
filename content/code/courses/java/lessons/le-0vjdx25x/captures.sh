#!/usr/bin/env bash
# The terminal sessions quoted in lesson 30 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies. Nothing is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns on -e; here a failing command is part of the transcript

fresh byvalue
put "$HERE/primitives-are-copied.md" Swap.java
block swap
run 'javac Swap.java && java Swap'
run 'javap -c Swap | sed -n 32,40p'
run 'javap -c Swap | sed -n 9,16p'

fresh byvalue/refs
put "$HERE/references-are-copied.md" Refs.java
block refs
run 'javac Refs.java && java Refs'
run 'javap -c Refs | grep -A 7 "void replace"'

fresh byvalue/myths
put "$HERE/the-misunderstanding.md" Myths.java
block myths
run 'javac Myths.java && java Myths'

fresh byvalue/living
put "$HERE/living-with-it.md" Returning.java
put "$HERE/living-with-it.md" Guard.java
block returning
run 'javac Returning.java && java Returning'
block guard
run 'javac Guard.java'
exit 0
