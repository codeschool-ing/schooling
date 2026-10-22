#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies.
#
# What is STAGED rather than typed: vars.jsh, the lines given to jshell, is
# written here with printf; the lesson shows it whole with `cat` first, as
# lesson 3 did with its own.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns -e on; here a failing command is a capture

fresh types
put "$HERE/eight-primitives.md" Ranges.java
put "$HERE/eight-primitives.md" Overflow.java
put "$HERE/eight-primitives.md" Population.java
put "$HERE/wrappers-and-boxing.md" Boxing.java
put "$HERE/wrappers-and-boxing.md" Missing.java
put "$HERE/var.md" VarMistakes.java

block ranges
run 'java Ranges.java'

block overflow
run 'java Overflow.java'

block population
run 'java Population.java'

block boxing
run 'java Boxing.java'

block missing
run 'java Missing.java; echo $?'
run 'javac -g Missing.java && java Missing'

block var
quiet "printf '%s\n' 'var title = \"Dom Casmurro\"' 'var year = 1899' 'var price = 39.90' 'var pages = 256L' 'var initial = '\''D'\''' '/vars' '/exit' > vars.jsh"
run 'cat vars.jsh'
run 'jshell --feedback normal < vars.jsh'

block var-mistakes
run 'javac VarMistakes.java'
exit 0
