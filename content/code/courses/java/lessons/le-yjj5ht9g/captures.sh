#!/usr/bin/env bash
# The terminal sessions quoted in lesson 39 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies.
#
# What is STAGED rather than typed: nothing but the files.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e

fresh annot
for f in Book OldDesk Counter Quiet Rule; do put "$HERE/language-annotations.md" $f.java; done
for f in Kept Check LoanChecks Runner; do put "$HERE/framework-annotations.md" $f.java; done
for f in NotBlank Member Validator Misplaced; do put "$HERE/your-own.md" $f.java; done

block override
run 'javac Book.java'

block deprecated
run 'javac OldDesk.java Counter.java'
run 'javac -Xlint:deprecation Counter.java'
run 'java Counter'

block suppress
run 'javac Quiet.java'

block functional
run 'javac Rule.java'

block retention
run 'javac Kept.java && java Kept'
run 'javap -v "Kept\$Target.class" | grep -A2 "Annotations:"'

block runner
run 'javac Check.java LoanChecks.java Runner.java && java Runner LoanChecks'

block validator
run 'javac NotBlank.java Member.java Validator.java && java Validator'

block misplaced
run 'javac Misplaced.java'
exit 0
