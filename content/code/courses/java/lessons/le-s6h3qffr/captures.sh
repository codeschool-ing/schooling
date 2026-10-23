#!/usr/bin/env bash
# The terminal sessions quoted in lesson 29 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies.
#
# What is STAGED rather than typed: nothing on the machine. The ISBN, the page
# counts, running times and issue number in the programs are made up for the
# lesson.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns on -e; here a failing command is part of the transcript

fresh records
put "$HERE/records.md" Records.java
block records
run 'javac Records.java && java Records'
run 'javap -p Book'

fresh records/compact
put "$HERE/compact-constructors.md" Checked.java
put "$HERE/compact-constructors.md" Shelves.java
block checked
run 'javac Checked.java && java Checked'
block shelves
run 'javac Shelves.java && java Shelves'

fresh records/patterns
put "$HERE/patterns.md" Patterns.java
block patterns
run 'javac Patterns.java && java Patterns'
run 'javac --release 17 Patterns.java 2>&1 | head -4'

fresh records/magazines
put "$HERE/patterns.md" Magazines.java
block magazines
run 'javac Magazines.java'

fresh records/not
put "$HERE/when-not.md" Loan.java
put "$HERE/when-not.md" Special.java
block not
run 'javac Loan.java'
run 'javac Special.java'
exit 0
