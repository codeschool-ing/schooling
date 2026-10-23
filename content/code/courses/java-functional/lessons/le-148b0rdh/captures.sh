#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of java-functional, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program it runs is taken
# out of the lesson's own English .md, so the file the student copies is the
# file that ran.
#
#   sudo bash ../../lab.sh setup      # once: OpenJDK 25, Maven and ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana saved, written by src and
# put below, and in when-it-fails a second JDK. The machine also has Ubuntu's
# openjdk-21-jdk installed beside 25, as a machine that had Java before this
# course would; two-jdks runs its java by its full path, and maven-old-java
# sets JAVA_HOME to it on the command line, which is what a stale line in
# ~/.bashrc does.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4 and Maven
# 3.8.7, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

block policy
home 'apt-cache policy openjdk-25-jdk | head -n 5'

block versions
home 'java -version'
home 'javac -version'
home 'mvn -B -v'

block first-run
at fp/lambdas
src Hello.java your-machine.md
home 'mkdir -p ~/fp/lambdas'
home 'cd ~/fp/lambdas'
on 'java Hello.java'
on 'ls'

block two-jdks
on 'javac -d out Hello.java'
on 'ls /usr/lib/jvm'
on '/usr/lib/jvm/java-21-openjdk-amd64/bin/java -cp out Hello'

block maven-old-java
on 'JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 mvn -B -v'

block typo
on 'java Helo.java'

block public-name
src Greeting.java your-machine.md Hello.java
on 'javac Greeting.java'

block quotes
src Quotes.java when-it-fails.md
on 'java Quotes.java'

block run
at fp/lambdas
src BeforeLambdas.java before-lambdas.md
on 'java BeforeLambdas.java'

block classes
on 'javac -d out BeforeLambdas.java'
on 'ls out'
on 'javap -p out/BeforeLambdas.class'
on 'javap -c -p out/BeforeLambdas.class | grep invokedynamic'

block shapes
src Shapes.java syntax.md
lab exec "$DIR" 'java Shapes.java' 2>&1

block no-target
src NoTarget.java syntax.md
on 'javac -d out NoTarget.java'

block capture
src Capture.java capture.md
on 'java Capture.java'

block counter
src Counter.java capture.md
on 'javac -d out Counter.java'

block reassigned
src Reassigned.java capture.md
on 'javac -d out Reassigned.java'

block this
src WhoIsThis.java capture.md
on 'java WhoIsThis.java'

block shadow
src Shadow.java capture.md
on 'javac -d out Shadow.java'
