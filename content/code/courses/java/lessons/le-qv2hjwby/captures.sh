#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of java, as a script that produces
# them. Every block of output starts with `##### <name>`.
#
#   sudo bash ../../lab.sh build && sudo bash ../../lab.sh install   # once
#   sudo bash captures.sh
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program is
# lifted out of the lesson's own .md by ../../lab.sh, so the file that runs
# here is the block the student copies.
#
# What is STAGED rather than typed:
#   - try.jsh, the lines given to jshell, is written here with printf; the
#     lesson shows it whole with `cat` before using it, which is where the
#     student copies it from;
#   - ~/.java, the user preferences directory jshell creates on its first run
#     (lesson 1 section 03), is removed first so the transcript starts from the
#     machine lesson 1 left, where jshell had already run once.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns -e on; here a failing command is a capture

fresh syntax
put "$HERE/hello-line-by-line.md" Hello.java
put "$HERE/hello-line-by-line.md" Oops.java

block hello
run 'java Hello.java'

block semicolon
run 'javac Oops.java; echo $?'
run 'ls'

block case
run "mkdir -p case && sed 's/System.out/system.out/' Hello.java > case/Hello.java"
run 'javac case/Hello.java'

block filename
run 'cp Hello.java Greeting.java && javac Greeting.java'
run 'rm Greeting.java'

block names
put "$HERE/naming-conventions.md" LoanDesk.java
run 'java LoanDesk.java'

block javadoc
put "$HERE/comments-and-javadoc.md" Greeter.java
run 'java Greeter.java'
run 'javadoc -quiet -d docs Greeter.java'
run 'ls docs | head -5'
run 'grep -o "Returns a greeting for one member." docs/Greeter.html | head -1'

block jshell
quiet "printf '%s\n' 'int pages = 7 / 2' 'pages * 3.0' 'String name = \"Ana\"' 'name.length()' 'name.toUpperCase()' '/vars' '/exit' > try.jsh"
run 'cat try.jsh'
run 'jshell --feedback normal < try.jsh'

block compact
put "$HERE/trying-code.md" Hi.java
run 'java Hi.java'
run 'javac Hi.java && javap Hi.class'
run 'javac --release 21 Hi.java'
exit 0
