#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of java, as a script that produces
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

block fields
fresh static
put "$HERE/static-fields.md" Member.java
put "$HERE/static-fields.md" Counter.java
run 'javac Counter.java && java Counter'
run 'javap -p Member'
run 'javac -Xlint:static Counter.java'

block methods
put "$HERE/static-methods.md" Isbns.java
put "$HERE/static-methods.md" Check.java
run 'javac Check.java && java Check'

block greeter
put "$HERE/static-methods.md" Greeter.java 1
run 'javac Greeter.java'
put "$HERE/static-methods.md" Greeter.java 2
run 'javac Greeter.java && java Greeter'

block shared
put "$HERE/static-pitfalls.md" Branch.java
put "$HERE/static-pitfalls.md" Branches.java
run 'javac Branches.java && java Branches'

block constant
put "$HERE/static-pitfalls.md" Limits.java 1
put "$HERE/static-pitfalls.md" LimitMain.java
run 'javac LimitMain.java Limits.java && java LimitMain'
put "$HERE/static-pitfalls.md" Limits.java 2
run 'javac Limits.java && java LimitMain'
run 'javap -c LimitMain | grep -A4 "main("'
run 'javac LimitMain.java Limits.java && java LimitMain'

block imports
put "$HERE/static-pitfalls.md" Imports.java
run 'javac Imports.java && java Imports'
exit 0
