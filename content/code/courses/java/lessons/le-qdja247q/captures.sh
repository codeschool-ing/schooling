#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies. Nothing else is staged: sections 02 and 03
# share ~/members, and section 04 works in ~/ctors because it has a Book of
# its own.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a command that fails is part of a transcript here

block fields
fresh members
put "$HERE/fields.md" Member.java
put "$HERE/fields.md" Defaults.java
run 'javac Defaults.java && java Defaults'

block methods
put "$HERE/methods.md" Book.java
put "$HERE/methods.md" UseBook.java
run 'javac UseBook.java && java UseBook'
run 'javap -p Book'

block wrong-call
put "$HERE/methods.md" WrongCall.java
run 'javac WrongCall.java'

block constructors
fresh ctors
put "$HERE/constructors.md" Book.java
put "$HERE/constructors.md" Main.java
run 'javac Main.java && java Main'
run 'javap -p Book'

block no-default
put "$HERE/constructors.md" OldMain.java
run 'javac OldMain.java'

block shadow
put "$HERE/constructors.md" Copy.java
put "$HERE/constructors.md" CopyMain.java
run 'javac CopyMain.java && java CopyMain'
exit 0
