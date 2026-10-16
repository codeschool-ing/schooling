#!/usr/bin/env bash
# The terminal sessions quoted in lesson 33 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies.
#
# What is STAGED rather than typed: nothing but the files, put below. The
# timings of QueueCost differ on every run; the lesson quotes one run of this
# script and says so.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a program that fails on purpose must not end the script

fresh queues
put "$HERE/queues.md" Desk.java
put "$HERE/queues.md" Holds.java
put "$HERE/deques-and-stacks.md" Undo.java
put "$HERE/choosing.md" QueueCost.java

block desk
run 'java Desk.java'

block holds
run 'java Holds.java'

block undo
run 'java Undo.java'

block cost
run 'java QueueCost.java'
exit 0
