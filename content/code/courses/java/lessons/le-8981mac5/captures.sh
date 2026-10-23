#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies.
#
# What is STAGED rather than typed: nothing but the files, which the lesson
# shows whole.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns on -e; a program that fails is part of the lesson

fresh maths
put "$HERE/operators.md" Operators.java
put "$HERE/the-math-class.md" MathClass.java
put "$HERE/floating-point.md" Floats.java
put "$HERE/bigdecimal.md" Money.java
put "$HERE/bigdecimal.md" Cents.java

block operators
run 'java Operators.java; echo $?'

block math
run 'java MathClass.java'

block floats
run 'java Floats.java'

block money
run 'java Money.java'

block cents
run 'java Cents.java'
exit 0
