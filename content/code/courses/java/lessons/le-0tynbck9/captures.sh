#!/usr/bin/env bash
# The terminal sessions quoted in lesson 36 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies. checked-and-unchecked.md shows
# Count.java twice, first without and then with `throws IOException`; the
# script puts the first, compiles it, and then the second (K = 1, then 2).
#
# What is STAGED rather than typed: the files, put below; loans.txt is
# written with printf, which the lesson shows as a command.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a program that fails on purpose must not end the script

fresh exc
put "$HERE/throwing-and-catching.md" Fine.java
put "$HERE/throwing-and-catching.md" Desk.java
put "$HERE/finally.md" Always.java

block fine
run 'java Fine.java; echo "exit $?"'

block desk
run 'java Desk.java'

block unreported
put "$HERE/checked-and-unchecked.md" Count.java 1
run 'javac Count.java'

block declared
put "$HERE/checked-and-unchecked.md" Count.java 2
run 'javac Count.java && java Count'
run 'printf "Dune\nEmma\nUlysses\n" > loans.txt'
run 'java Count'

block always
run 'java Always.java; echo "exit $?"'
exit 0
