#!/usr/bin/env bash
# The terminal sessions quoted in lesson 32 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies.
#
# What is STAGED rather than typed: the files, put below, and the edit that
# puts sets.md's hashCode into BrokenKey.java, done by a few lines of Python
# where the student would use an editor. The
# timings of ListCost differ on every run; the lesson quotes one run of this
# script and says so.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh sets -e; a program that fails on purpose must not end the script

fresh colls
put "$HERE/lists.md" ListCost.java
put "$HERE/sets.md" Orders.java
put "$HERE/sets.md" BrokenKey.java
put "$HERE/maps.md" Counts.java

block lists
run 'java ListCost.java'

block sets
run 'java Orders.java'

block broken
run 'java BrokenKey.java'

block fixed
# The repair: the hashCode block of sets.md, put where BrokenKey.java's
# comment `// no hashCode...` stands, indented to the class's depth.
python3 - "$HERE/sets.md" "$LIVE/home/ana/colls/BrokenKey.java" <<'PY'
import re, sys
md, dest = sys.argv[1], sys.argv[2]
snip = re.search(r'^```java\n(@Override\npublic int hashCode.*?)^```$', open(md).read(), re.S | re.M).group(1)
snip = ''.join('        ' + l if l.strip() else l for l in snip.splitlines(True))
src = open(dest).read()
src = re.sub(r'^        // no hashCode.*\n', snip, src, flags=re.M)
open(dest, 'w').write(src)
PY
run 'java BrokenKey.java'

block maps
run 'java Counts.java'
exit 0
