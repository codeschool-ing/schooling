#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of java, as a script that produces
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
# shows whole. The two timings in Concat differ on every run; the lesson
# quotes one run of this script.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns on -e; a program that fails is part of the lesson

fresh strings
put "$HERE/immutability.md" Immutable.java
put "$HERE/immutability.md" Equality.java
put "$HERE/immutability.md" Receipt.java
put "$HERE/methods.md" Methods.java
put "$HERE/methods.md" Chars.java
put "$HERE/stringbuilder.md" Concat.java
put "$HERE/stringbuilder.md" Greeting.java
put "$HERE/formatting.md" Format.java

block immutable
run 'java Immutable.java'

block equality
run 'java Equality.java'

block textblock
run 'java Receipt.java'

block methods
run 'java Methods.java'

block chars
run 'java Chars.java'

block concat
run 'javac Concat.java && java Concat'

block indy
run 'javac Greeting.java && java Greeting'
run 'javap -c Greeting | grep -A5 "greet(java"'

block format
run 'java Format.java; echo $?'
exit 0
