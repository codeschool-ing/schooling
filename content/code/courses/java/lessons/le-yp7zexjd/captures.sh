#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of java, as a script that produces
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
# shows whole. Forever.java never ends by itself, so `timeout 1` stops it
# after a second; the line count it printed in that second differs on every run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns on -e; a program that fails is part of the lesson

fresh loops
put "$HERE/for-and-while.md" Counting.java
put "$HERE/for-each.md" Each.java
put "$HERE/break-continue-labels.md" Search.java
put "$HERE/for-and-while.md" Forever.java

block counting
run 'java Counting.java'

block each
run 'java Each.java'

block search
run 'java Search.java'

block forever
run 'javac Forever.java && timeout 1 java Forever | head -3'
run 'timeout 1 java Forever | wc -l'
exit 0
