#!/usr/bin/env bash
# The terminal sessions quoted in lesson 31 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies.
#
# What is STAGED rather than typed: nothing. Shifting.java measures time, so
# its two numbers differ on every run and on every machine; the lesson quotes
# one run of this script and says so.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns on -e; here a failing command is part of the transcript

fresh lists
put "$HERE/arraylist.md" Lists.java
block lists
run 'javac Lists.java && java Lists'

fresh lists/growth
put "$HERE/growth.md" Growth.java
put "$HERE/growth.md" Shifting.java
block growth
run 'javac Growth.java && java Growth'
run 'java --add-opens java.base/java.util=ALL-UNNAMED Growth'
block shifting
run 'javac Shifting.java && java Shifting'

fresh lists/views
put "$HERE/choosing.md" Views.java
block views
run 'javac Views.java && java Views'
exit 0
