#!/usr/bin/env bash
# The terminal sessions quoted in lesson 27 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies. Nothing else is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns on -e; here a failing command is part of the transcript

fresh init
put "$HERE/initialiser-blocks.md" Shelf.java
put "$HERE/the-order.md" Order.java

block shelf
run 'javac Shelf.java && java Shelf'
run 'javap -p Shelf'

block order
run 'javac Order.java && java Order'
run 'ls *.class'

fresh init/trap
put "$HERE/constructor-traps.md" Trap.java
put "$HERE/constructor-traps.md" Early.java

block trap
run 'javac Trap.java && java Trap'

block early
run 'javac Early.java && java Early'
run 'javac --release 21 Early.java'
exit 0
