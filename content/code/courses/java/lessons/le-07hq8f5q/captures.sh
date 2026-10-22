#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies. Nothing is staged.
#
# The depths Depth.java reaches may differ between runs and machines,
# because how much stack a frame takes depends on what the JIT has compiled
# by then; the lesson quotes one run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns -e on; here a failing command is a capture

fresh scope
put "$HERE/declaring.md" Fine.java
put "$HERE/declaring.md" Defaults.java
put "$HERE/scope.md" Blocks.java
put "$HERE/scope.md" Twice.java
put "$HERE/scope.md" Shadow.java
put "$HERE/lifetime.md" Depth.java

block fine
run 'javac Fine.java'
block defaults
run 'java Defaults.java'
block blocks
run 'javac Blocks.java'
block twice
run 'javac Twice.java'
block shadow
run 'java Shadow.java'
block depth
run 'javac Depth.java'
run 'java Depth'
run 'java Depth'
run 'java -Xss256k Depth'
run 'java -Xss4m Depth'
exit 0
