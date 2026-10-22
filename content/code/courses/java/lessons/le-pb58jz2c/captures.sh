#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of java, as a script that produces
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
# the removal of CardDemo.java, which exists only to show a compile error. The
# dates are fixed in the source, so nothing depends on the day it was run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns on -e, and here a failing command is often the point

fresh fluent
for f in Chains.java Receipt.java ReceiptDemo.java; do put "$HERE/returning-this.md" $f; done
block chains
run 'javac Chains.java && java Chains'
block receipt
run 'javac Receipt.java ReceiptDemo.java && java ReceiptDemo'
block void
put "$HERE/returning-this.md" Card.java
put "$HERE/returning-this.md" CardDemo.java
run 'javac Card.java CardDemo.java'
quiet 'rm Card.java CardDemo.java'

block builder
put "$HERE/builder.md" Loan.java
put "$HERE/builder.md" Lending.java
run 'javac Loan.java Lending.java && java Lending'
run 'ls Loan*.class'

block dates
put "$HERE/immutable-chains.md" Dates.java
run 'javac Dates.java && java Dates'
block fines
put "$HERE/immutable-chains.md" Fine.java
put "$HERE/immutable-chains.md" Fines.java
run 'javac Fine.java Fines.java && java Fines'
exit 0
