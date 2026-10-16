#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies. The edits the lesson asks the student to
# make are typed here as the `sed` commands the lesson shows.
#
# What is STAGED rather than typed: nothing beyond the files themselves.
# getClass().getName() and the class file names are the same on every run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns -e on; a compile error is a capture, not a reason to stop

block static-nested
fresh nested
put "$HERE/static-nested.md" Catalogue.java
run 'javac Catalogue.java && java Catalogue'
run 'ls'

block static-error
put "$HERE/static-nested.md" Shelf.java
run 'javac Shelf.java'

block inner
put "$HERE/inner-classes.md" Member.java
run 'javac Member.java && java Member'
run 'ls Member*'
run "javap -p 'Member\$Card'"

block inner-error
run "sed -i 's/ana.new Card(1)/new Card(1)/' Member.java"
run 'javac Member.java'

block anonymous
put "$HERE/local-and-anonymous.md" Sorting.java
run 'javac Sorting.java && java Sorting'
run 'ls Sorting*'

block local
put "$HERE/local-and-anonymous.md" Overdue.java
run 'javac Overdue.java && java Overdue'
run 'ls Overdue*'
run "sed -i '/Notice notice = new Notice/i\\        days = 21;' Overdue.java"
run 'javac Overdue.java'
exit 0
