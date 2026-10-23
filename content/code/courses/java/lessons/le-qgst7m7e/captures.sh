#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies.
#
# What is STAGED rather than typed: the files Ana saved, written by `put`.
# The dates in the loan programs are fixed in the source, so nothing here
# depends on the day it was run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns on -e, and here a failing command is often the point

fresh encap
put "$HERE/accessors.md" OpenBook.java
put "$HERE/accessors.md" OpenDemo.java
put "$HERE/accessors.md" Book.java
put "$HERE/accessors.md" BookDemo.java

block open
run 'javac OpenBook.java OpenDemo.java && java OpenDemo'

block private
run 'javac Book.java BookDemo.java && java BookDemo; echo $?'

block sneaky
put "$HERE/accessors.md" Sneaky.java
run 'javac Sneaky.java'
quiet 'rm Sneaky.java'

block leak
put "$HERE/invariants.md" Shelf.java
put "$HERE/invariants.md" LeakDemo.java
run 'javac Shelf.java LeakDemo.java && java LeakDemo'

block safe
put "$HERE/invariants.md" SafeShelf.java
put "$HERE/invariants.md" SafeDemo.java
run 'javac SafeShelf.java SafeDemo.java && java SafeDemo'

block ask
put "$HERE/tell-dont-ask.md" AskLoan.java
put "$HERE/tell-dont-ask.md" AskDemo.java
run 'javac AskLoan.java AskDemo.java && java AskDemo'

block tell
put "$HERE/tell-dont-ask.md" Loan.java
put "$HERE/tell-dont-ask.md" TellDemo.java
run 'javac Loan.java TellDemo.java && java TellDemo'
exit 0
