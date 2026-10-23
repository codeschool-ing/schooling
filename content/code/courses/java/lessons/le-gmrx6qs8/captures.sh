#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies. Where a lesson shows several versions
# of one file, the number after the file name says which.
#
# What is STAGED rather than typed: the files Ana saved, written by `put`, and
# the removal of each file that exists only to show a compile error, so that
# the next `javac *.java` compiles what the lesson says it does.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns on -e, and here a failing command is often the point

fresh overload
put "$HERE/overloading.md" Printer.java
put "$HERE/overloading.md" Ranking.java
block printer
run 'javac Printer.java && java Printer'
block ranking
run 'javac Ranking.java && java Ranking'
block ambiguous
put "$HERE/overloading.md" Ambiguous.java
run 'javac Ambiguous.java'
block twice
put "$HERE/overloading.md" Twice.java
run 'javac Twice.java'
quiet 'rm Ambiguous.java Twice.java'

fresh overload/override
for f in Item.java Book.java Counter.java; do put "$HERE/overriding.md" $f; done
put "$HERE/overriding.md" Typo.java 1
block silent
run 'javac *.java && java Counter'
put "$HERE/overriding.md" Typo.java 2
block caught
run 'javac Typo.java'
put "$HERE/overriding.md" Quiet.java
block weaker
run 'javac Quiet.java'

fresh overload/trap
put "$HERE/the-trap.md" Book.java 1
put "$HERE/the-trap.md" Trap.java
block trap
run 'javac Book.java Trap.java && java Trap'
put "$HERE/the-trap.md" Book.java 2
block annotated
run 'javac Book.java'
put "$HERE/the-trap.md" Book.java 3
block fixed
run 'javac Book.java Trap.java && java Trap'
exit 0
