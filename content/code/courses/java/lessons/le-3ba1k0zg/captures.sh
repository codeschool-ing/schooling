#!/usr/bin/env bash
# The terminal sessions quoted in lesson 35 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies.
#
# What is STAGED rather than typed: nothing but the files, put below.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a program that fails on purpose must not end the script

fresh generics
put "$HERE/typed-collections.md" Raw.java
put "$HERE/typed-collections.md" Typed.java
put "$HERE/generic-types-and-methods.md" Box.java
put "$HERE/generic-types-and-methods.md" UseBox.java
put "$HERE/generic-types-and-methods.md" NoOrder.java
put "$HERE/wildcards.md" Invariant.java
put "$HERE/wildcards.md" Wild.java
put "$HERE/type-erasure.md" Erased.java
put "$HERE/type-erasure.md" Limits.java

block raw
run 'javac Raw.java'
run 'javac -Xlint:unchecked Raw.java'
run 'java Raw'

block typed
run 'javac Typed.java'

block box
run 'javac Box.java UseBox.java && java UseBox'

block noorder
run 'javac NoOrder.java'

block invariant
run 'javac Invariant.java'

block wild
run 'javac Wild.java && java Wild'

block erased
run 'java Erased.java'
run 'javap -c Box'
run 'javap -c UseBox | grep -A1 "Box.take"'

block limits
run 'javac Limits.java'
exit 0
