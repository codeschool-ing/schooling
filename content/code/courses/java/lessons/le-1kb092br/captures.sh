#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of java, as a script that produces
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

fresh arrays
put "$HERE/declaring.md" Declaring.java
put "$HERE/traversing.md" Traversing.java
put "$HERE/multidimensional.md" Grid.java

block declaring
run 'java Declaring.java'

block traversing
run 'java Traversing.java'

block grid
run 'java Grid.java'
run 'javac Grid.java && java Grid 2>&1 | tail -2'
run 'javac -g Grid.java && java Grid 2>&1 | tail -2'
exit 0
