#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of java-functional, as a script that
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
# The spin count and the lost updates change from run to run; the lesson
# quotes one run of this script, on 4 processors.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/volatile

block fixed
src VolatileStop.java the-fix.md
on 'java VolatileStop.java'

block handoff
src Handoff.java what-it-guarantees.md
lab exec "$DIR" 'java Handoff.java' 2>&1

block lost
src LostUpdates.java what-it-does-not.md
on 'java LostUpdates.java'

block lazy
src Lazy.java when-to-use-it.md
on 'java Lazy.java'
