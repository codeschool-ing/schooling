#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies.
#
# What is STAGED rather than typed: the files Ana saved, written by `put`, and
# the removal of Visible.java, which exists only to show a compile error, so
# that the next `javac *.java` compiles what the lesson says it does.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns on -e, and here a failing command is often the point

fresh binding
for f in Item.java Book.java Dvd.java Desk.java; do put "$HERE/declared-and-actual-type.md" $f; done
block desk
run 'javac *.java && java Desk'
block visible
put "$HERE/declared-and-actual-type.md" Visible.java
run 'javac Visible.java'
quiet 'rm Visible.java'
block casts
put "$HERE/declared-and-actual-type.md" Casts.java
run 'javac Casts.java && java Casts'

block say
put "$HERE/dynamic-dispatch.md" Say.java
run 'javac Say.java && java Say'
run 'javap -c Say | grep -A4 "say(Item)"'

fresh binding/hiding
for f in Parent.java Child.java Hiding.java; do put "$HERE/what-is-not-dynamic.md" $f; done
block hiding
run 'javac *.java && java Hiding'
run 'javap -c Hiding | grep -E "getfield|invoke"'
run 'javap -c -p Parent | grep -A3 "callSecret()"'
exit 0
