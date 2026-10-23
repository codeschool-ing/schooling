#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies. Where a lesson shows a file twice, before
# and after a change, `put` takes the first or the second version by number,
# in the order the lesson shows them; that is the edit Ana makes in her
# editor between two commands. Nothing else is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a command that fails is part of a transcript here

block locals
fresh final
put "$HERE/final-variables.md" Locals.java
run 'javac Locals.java'

block blank
put "$HERE/final-variables.md" Book.java 1
run 'javac Book.java'
put "$HERE/final-variables.md" Book.java 2
run 'javac Book.java'
put "$HERE/final-variables.md" Book.java 3
run 'javac Book.java && javap -p Book'

block refs
put "$HERE/final-variables.md" Notes.java
run 'javac Notes.java && java Notes'
put "$HERE/final-variables.md" Reassign.java
run 'javac Reassign.java'

block methods
fresh final2
put "$HERE/final-methods-and-classes.md" Item.java
put "$HERE/final-methods-and-classes.md" Dvd.java
run 'javac Dvd.java'

block classes
put "$HERE/final-methods-and-classes.md" Isbn.java
put "$HERE/final-methods-and-classes.md" FakeIsbn.java
run 'javac FakeIsbn.java'
put "$HERE/final-methods-and-classes.md" MyString.java
run 'javac MyString.java'
run 'javap java.lang.String | head -2'

block capture
fresh capture
put "$HERE/effectively-final.md" Capture.java 1
run 'javac Capture.java && java Capture'
put "$HERE/effectively-final.md" Capture.java 2
run 'javac Capture.java'
put "$HERE/effectively-final.md" Lambda.java
run 'javac Lambda.java'
exit 0
