#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of java-functional, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program it
# runs is taken out of the lesson's own English .md, so the file the student
# copies is the file that ran.
#
#   sudo bash ../../lab.sh setup      # once: OpenJDK 25, Maven and ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana saved, written by src.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/optional
src Catalogue.java the-trouble-with-null.md

block npe
src NullTrouble.java the-trouble-with-null.md
on 'java NullTrouble.java'

block npe-g
on 'javac -g -d out Catalogue.java NullTrouble.java'
on 'java -cp out NullTrouble'

block making
src Making.java making-one.md
on 'java Making.java'

block chaining
src Chaining.java chaining.md
lab exec "$DIR" 'java Chaining.java' 2>&1

block get
src Antipattern.java the-get-antipattern.md
on 'java Antipattern.java'
