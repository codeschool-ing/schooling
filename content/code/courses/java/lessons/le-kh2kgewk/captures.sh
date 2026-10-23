#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies. Where a lesson shows two versions of
# one file, the number after the file name says which.
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

fresh iface
for f in Lendable.java Book.java Dvd.java Desk.java; do put "$HERE/interfaces.md" $f; done
block desk
run 'javac *.java && java Desk'
block magazine
put "$HERE/interfaces.md" Magazine.java
run 'javac Magazine.java'
quiet 'rm Magazine.java'
block nope
put "$HERE/interfaces.md" Nope.java
run 'javac Nope.java'
quiet 'rm Nope.java'

fresh iface/defaults
for f in Book.java Dvd.java; do put "$HERE/interfaces.md" $f; done
for f in Lendable.java Game.java Shelf.java; do put "$HERE/default-methods.md" $f; done
block defaults
run 'javac *.java && java Shelf'
run 'javap Lendable'

fresh iface/diamond
put "$HERE/diamond.md" Printed.java
put "$HERE/diamond.md" Recorded.java
put "$HERE/diamond.md" Audiobook.java 1
block clash
run 'javac Printed.java Recorded.java Audiobook.java'
put "$HERE/diamond.md" Audiobook.java 2
for f in Catalogue.java Leaflet.java Labels.java; do put "$HERE/diamond.md" $f; done
block resolved
run 'javac *.java && java Labels'

fresh iface/sealed
put "$HERE/sealed.md" Item.java
put "$HERE/sealed.md" Book.java
put "$HERE/sealed.md" Dvd.java 1
block unmarked
run 'javac Item.java Book.java Dvd.java'
put "$HERE/sealed.md" Dvd.java 2
put "$HERE/sealed.md" Magazine.java
block magazine-sealed
run 'javac Item.java Book.java Dvd.java Magazine.java'
quiet 'rm Magazine.java'
put "$HERE/sealed.md" Rules.java
block rules
run 'javac *.java && java Rules'
exit 0
