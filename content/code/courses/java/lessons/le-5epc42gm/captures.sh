#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies. Nothing is staged.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns -e on; here a failing command is a capture

fresh convert
for f in widening:Widen narrowing-casts:Lossy narrowing-casts:Narrow promotion:SmallSum promotion:Promote parsing:Copies parsing:Price; do
  put "$HERE/${f%%:*}.md" "${f##*:}.java"
done

block widen
run 'java Widen.java'
block lossy
run 'javac Lossy.java'
block narrow
run 'java Narrow.java'
block smallsum
run 'javac SmallSum.java'
block promote
run 'java Promote.java'
block copies
run 'javac Copies.java Price.java'
run 'java Copies 21'
run 'java Copies "21 "'
run 'java Copies twenty; echo $?'
block price
run 'java Price 39.90'
run 'java Price " 39.90 "'
run 'java Price 39,90'
exit 0
