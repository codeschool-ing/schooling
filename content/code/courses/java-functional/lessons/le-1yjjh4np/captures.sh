#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of java-functional, as a script that
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
# The counts lost by the HashMap and the timings of Handover.java change from
# run to run; the lesson quotes one run of this script, on 4 processors.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/concurrent

block atomics
src Atomics.java atomics.md
lab exec "$DIR" 'java Atomics.java' 2>&1

block words
src WordCount.java concurrent-maps.md
on 'java WordCount.java'

block handover
src Handover.java blocking-queues.md
on 'java Handover.java'

block twomore
src TwoMore.java choosing.md
on 'java TwoMore.java'
