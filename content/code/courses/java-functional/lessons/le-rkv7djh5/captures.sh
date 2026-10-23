#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of java-functional, as a script that
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
# The order of lines printed by two threads, the timings and the memory
# figures change from run to run; the lesson quotes one run of this script,
# on 4 processors and 15 GB of memory.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/threads

block first
src First.java creating-and-starting.md
on 'java First.java'

block states
src States.java the-life-of-a-thread.md
on 'java States.java'

block cost
src Cost.java what-one-costs.md
on 'java Cost.java 1000'
on 'java Cost.java 10000'

block failing
src Failing.java when-a-thread-fails.md
on 'java Failing.java'
