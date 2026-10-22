#!/usr/bin/env bash
# The terminal sessions quoted in lesson 38 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled
# here is the block the student copies.
#
# What is STAGED rather than typed: nothing but the files. Deep's stack
# overflow prints over a thousand frames; the lesson shows the first lines
# through `head`, as the command it prints says. The depth it reaches depends
# on the JVM's stack size and on what the JIT has compiled, so it differs from
# run to run; the lesson quotes one run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e

fresh hierarchy
for f in Ancestry Deep; do put "$HERE/throwable-hierarchy.md" $f.java; done
for f in LoanNotAllowedException Desk Careless CatalogueUnavailableException Catalogue; do
  put "$HERE/your-own-exception.md" $f.java
done
for f in Fines FinesLoud Flow; do put "$HERE/good-practice.md" $f.java; done

block ancestry
run 'javac Ancestry.java Deep.java && java Ancestry'

block deep
run 'java Deep 2>&1 | head -4'
run 'java Deep > deep.txt 2>&1; echo "exit $?"; wc -l < deep.txt; grep -c "after the try" deep.txt'

block desk
run 'javac LoanNotAllowedException.java Desk.java && java Desk'

block careless
run 'javac Careless.java'

block catalogue
run 'javac CatalogueUnavailableException.java Catalogue.java'
run 'printf "Effective Java\nJava Concurrency in Practice\n" > catalogue.txt && java Catalogue catalogue.txt'
run 'java Catalogue missing.txt'

block fines
run 'javac Fines.java FinesLoud.java Flow.java && java Fines'
run 'java FinesLoud'

block flow
run 'java Flow'
exit 0
