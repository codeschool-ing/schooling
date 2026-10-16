#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file compiled here
# is the block the student copies. Section 02 works in ~/abstract, sections 03
# and 04 in ~/abstract/fees, as the lesson says.
#
# What is STAGED rather than typed: nothing beyond the files.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # lab.sh turns -e on; a compile error is a capture, not a reason to stop

block abstract
fresh abstract
put "$HERE/abstract-classes.md" Item.java
put "$HERE/abstract-classes.md" Book.java
put "$HERE/abstract-classes.md" Magazine.java
put "$HERE/abstract-classes.md" Desk.java
run 'javac Item.java Book.java Desk.java'
run 'javac Magazine.java'

block abstract-fixed
run "sed -i '/Item mystery/d' Desk.java && javac Item.java Book.java Desk.java && java Desk"

block fees
fresh abstract/fees
put "$HERE/template-method.md" Loanable.java
put "$HERE/template-method.md" Book.java
put "$HERE/template-method.md" Dvd.java
put "$HERE/template-method.md" Fees.java
run 'javac Loanable.java Book.java Dvd.java Fees.java && java Fees'

block final
put "$HERE/template-method.md" Ebook.java
run 'javac Ebook.java'

block javap
run 'javap -p Loanable'

block anonymous
put "$HERE/when-abstract.md" Special.java
run 'javac Special.java && java Special'
exit 0
