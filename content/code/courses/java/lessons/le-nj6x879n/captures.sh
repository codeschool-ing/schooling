#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies.
#
# What is STAGED rather than typed: nothing beyond the files. The garbage
# collector's log carries times, and its pauses, heap sizes and counts differ
# from run to run and machine to machine; the lesson quotes one run and says
# so. The machine has 4 processors and 15 GB of memory, which decides the
# collector's defaults (G1, and the heap sizes it chooses).
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns -e on; an OutOfMemoryError is a capture, not a reason to stop

block construction
fresh lifecycle
put "$HERE/construction.md" Loan.java
run 'javac Loan.java && java Loan'
run 'javap -c Loan | grep -A6 "static void main"'

block churn
put "$HERE/reachability.md" Churn.java
put "$HERE/reachability.md" Hoard.java
put "$HERE/reachability.md" Request.java
run 'javac Churn.java Hoard.java Request.java'
run 'java -Xmx32m Churn'
run 'java -Xmx32m -Xlog:gc Churn > gc.log; head -4 gc.log'
run 'grep -c Pause gc.log'

block hoard
run 'java -Xmx32m Hoard; echo $?'

block request
run 'java -Xlog:gc Request'
run 'java -XX:+DisableExplicitGC -Xlog:gc Request'

block finalize
put "$HERE/cleanup.md" Tidy.java
run 'javac Tidy.java'
run 'java Tidy'
exit 0
