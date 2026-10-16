#!/usr/bin/env bash
# The terminal sessions quoted in lesson 37 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies.
#
# What is STAGED rather than typed: nothing but the files. Resource.java has
# two versions, the-problem.md's and try-with-resources.md's; the second
# replaces the first in ~/twr when section 03 starts, as it does for the
# student. loans.txt is written with printf, as the lesson shows.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e

fresh twr
put "$HERE/the-problem.md" Resource.java
put "$HERE/the-problem.md" Leak.java
put "$HERE/the-problem.md" Finally.java
put "$HERE/the-problem.md" Masked.java

block leak
run 'javac *.java'
run 'java Leak; echo "exit $?"'

block finally
run 'java Finally'

block masked
run 'java Masked'

put "$HERE/try-with-resources.md" Resource.java
put "$HERE/try-with-resources.md" Twr.java
put "$HERE/try-with-resources.md" Order.java
put "$HERE/try-with-resources.md" CountLines.java
put "$HERE/try-with-resources.md" NotCloseable.java
quiet 'rm -f *.class'

block twr
run 'javac Resource.java Twr.java Order.java CountLines.java'
run 'java Twr'

block order
run 'java Order'

block file
run 'printf "978-0-13-468599-1 ana\n978-1-61729-136-8 rui\n978-0-596-00920-5 ana\n" > loans.txt'
run 'java CountLines loans.txt'
run 'java CountLines missing.txt'

block not-closeable
run 'javac NotCloseable.java'

put "$HERE/suppressed.md" Suppressed.java
put "$HERE/suppressed.md" Inspect.java

block suppressed
run 'javac Suppressed.java Inspect.java'
run 'java Suppressed'

block inspect
run 'java Inspect'
exit 0
