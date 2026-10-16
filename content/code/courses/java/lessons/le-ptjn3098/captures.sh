#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies.
#
# What is STAGED rather than typed:
#   - on-the-heap: the lesson has Ana start `java Shelf` in one terminal and
#     type jps and jcmd in a second. Here Shelf is started in the background
#     with its output sent to a file, and the first terminal's transcript is
#     that file printed under the prompt she typed. The sleep before jps
#     stands in for the time it takes her to switch terminals.
#   - The lab machine is shared with other lessons' captures, so the jps
#     block waits until ana runs no other JVM before starting Shelf.
#   - The identity hash codes after `Book@` and the process id differ on
#     every run; the lesson quotes one run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a command that fails is part of a transcript here

block class-and-object
fresh objects
put "$HERE/class-and-object.md" Book.java
put "$HERE/class-and-object.md" Main.java
run 'javac Book.java Main.java'
run 'ls'
run 'java Main'
run 'javap -p Book'

block references
put "$HERE/references.md" Refs.java
run 'javac Refs.java && java Refs'
run 'javac -g Refs.java && java Refs'

block heap
put "$HERE/on-the-heap.md" Shelf.java
quiet 'javac Shelf.java'
# The lab machine is shared with other captures, whose JVMs jps would list
# too: wait until ana runs no other JVM, so the listing is this lesson's.
for i in $(seq 1 120); do
  [ "$(bash "$LAB_SH" exec objects 'jps -q | wc -l')" = 1 ] && break
  sleep 1
done
quiet 'setsid java Shelf > shelf.out 2>&1 < /dev/null &'
sleep 2
run 'jps'
run 'jcmd Shelf GC.class_histogram | head -3'
run 'jcmd Shelf GC.class_histogram | grep -E " Book$|\[LBook;"'
sleep 9
block heap-first-terminal
printf 'ana@vm:~/objects$ java Shelf\n'
bash "$LAB_SH" exec objects 'cat shelf.out'
exit 0
