#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies. Where a lesson shows a file twice, before
# and after a change, `put` takes the first or the second version by number,
# in the order the lesson shows them. Nothing else is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a command that fails is part of a transcript here

block levels
fresh access
put "$HERE/four-levels.md" lib/Shelf.java
put "$HERE/four-levels.md" Main.java 1
run 'javac Main.java'
put "$HERE/four-levels.md" lib/Inside.java
run 'javac lib/Inside.java'
put "$HERE/four-levels.md" Main.java 2
run 'javac Main.java && java Main'
run 'ls lib'

block open
fresh loans
put "$HERE/why-private.md" OpenLoan.java
put "$HERE/why-private.md" OpenMain.java
run 'javac OpenMain.java && java OpenMain'

block private
put "$HERE/why-private.md" Loan.java
put "$HERE/why-private.md" LoanMain.java
run 'javac LoanMain.java && java LoanMain'
put "$HERE/why-private.md" Cheat.java
run 'javac Cheat.java'

block one-public
fresh catalogue
put "$HERE/one-public-class.md" Catalogue.java 1
run 'javac Catalogue.java'
put "$HERE/one-public-class.md" Catalogue.java 2
run 'javac Catalogue.java && java Catalogue'
run 'ls'
exit 0
