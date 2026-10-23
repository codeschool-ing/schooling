#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies; Dvd.java is written twice, as the lesson
# shows it twice. The edits the lesson asks for are the `sed` commands shown.
#
# What is STAGED rather than typed: nothing beyond the files. The hash after
# `Book@` differs on every run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns -e on; a compile error is a capture, not a reason to stop

block extends
fresh inherit
put "$HERE/extends.md" Item.java
put "$HERE/extends.md" Book.java
put "$HERE/extends.md" Dvd.java
put "$HERE/extends.md" Lending.java
run 'javac *.java && java Lending'
run "javap -p Book"

block no-super
run "sed -i 's/        super(title, year);//' Book.java && javac Book.java"
put "$HERE/extends.md" Book.java

block private-field
run "sed -i 's/return author;/return author + \", \" + year;/' Book.java && javac Book.java"
put "$HERE/extends.md" Book.java

block chain
put "$HERE/overriding-basics.md" Dvd.java
put "$HERE/overriding-basics.md" Chain.java
run 'javac *.java && java Chain'

block two-parents
run "sed -i 's/public class Book extends Item {/public class Book extends Item, Dvd {/' Book.java && javac Book.java"
put "$HERE/extends.md" Book.java

block counting
put "$HERE/limits.md" CountingSet.java
put "$HERE/limits.md" CountingShelf.java
run 'java CountingSet.java'
run 'java CountingShelf.java'
exit 0
