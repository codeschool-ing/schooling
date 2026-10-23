#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of java-functional, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program it
# runs is taken out of the lesson's own English .md, so the file the student
# copies is the file that ran.
#
#   sudo bash ../../lab.sh setup      # once: OpenJDK 25, Maven and ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana saved, written by src. The
# notes.txt that OwnInterface.java reads is typed, with printf, in the
# transcript that shows it.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/interfaces

block one
src OneMethod.java one-method.md
on 'java OneMethod.java'

block two
src TwoMethods.java one-method.md
on 'javac -d out TwoMethods.java'

block four
src TheFour.java the-four.md
lab exec "$DIR" 'java TheFour.java' 2>&1

block list
src ListFunctions.java primitives.md
on 'java ListFunctions.java'

block prims
src Primitives.java primitives.md
on 'java Primitives.java'

block checked
src Checked.java your-own.md
on 'javac -d out Checked.java'

block own
src OwnInterface.java your-own.md
on "printf 'Lumen opens at nine on weekdays.\n' > notes.txt"
on 'java OwnInterface.java'
