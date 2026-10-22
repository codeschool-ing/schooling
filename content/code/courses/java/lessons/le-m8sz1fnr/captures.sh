#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of java, as a script that produces
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
#   - other programs of ana's may be running while this records, so the
#     commands that list JVMs are filtered to Wait with grep, as the lesson
#     says;
#   - `java Wait > wait.log &` is printed and run as typed, outside the pipe
#     the other commands' output goes through, and is followed by a pause of
#     three seconds, so that Wait has printed its line before anything looks
#     at it. It is stopped at the end with pkill. Process ids,
#     memory and thread counts differ on every run; the lesson quotes one.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh"
set +e   # sourcing lab.sh turns -e on; here a failing command is a capture

fresh life
put "$HERE/compile-and-run.md" Greet.java

block compile
run 'javac -d out Greet.java'
run 'ls; ls out'
run 'java -cp out Greet Ana Bruno'
run 'java -cp out Greet; echo $?'
run 'java -cp out Greet Ana > hello.txt; echo $?; cat hello.txt'

block wrong
run 'java Greet Ana'
run 'java -cp out Greet.class'
run 'java -cp out greet Ana'

block launcher
fresh launch
put "$HERE/compile-and-run.md" Greet.java
run 'java Greet.java Ana'
run 'ls'
put "$HERE/source-launcher.md" Main.java
put "$HERE/source-launcher.md" Shout.java
run 'java Main.java'
run 'ls'
run "echo 'class Broken {' > Broken.java; java Main.java"
run 'rm Broken.java'
run "(echo '#!/usr/bin/java --source 25'; cat Greet.java) > greet"
run 'chmod +x greet && ./greet Ana'
run 'head -3 greet'
run 'cp greet greet.java && java greet.java Ana'
run 'time java Greet.java Ana'
run 'javac Greet.java && time java Greet Ana'

block process
fresh proc
put "$HERE/the-running-process.md" Wait.java
run 'javac Wait.java'
# printed and run without the capture's pipe: a background JVM would hold it
# open for its whole minute, and the transcript would wait with it.
_prompt proc 'java Wait > wait.log &'; quiet 'java Wait > wait.log &'
quiet 'sleep 3'
run 'cat wait.log'
run 'jps -l | grep -w Wait'
run 'jcmd Wait VM.version'
run 'jcmd Wait VM.uptime'
run 'jcmd Wait Thread.print | grep -c "^\""'
run 'ps -o pid,rss,args -C java | grep -E "PID|Wait"'
quiet 'pkill -u ana -f "^java Wait$"'

block classes
at life
run 'java -Xlog:class+load -cp out Greet Ana | wc -l'
run 'java -Xlog:class+load -cp out Greet Ana | grep -E "Greet|Hello, Ana"'
run 'java -Xlog:class+load -cp out Greet Ana | grep -c "shared objects file"'
exit 0
