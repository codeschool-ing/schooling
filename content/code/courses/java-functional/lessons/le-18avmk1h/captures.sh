#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of java-functional, as a script that
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
# timings of Buffered.java change from run to run; the lesson quotes one run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/io

block encoding
src Encoding.java bytes-and-characters.md
on 'java Encoding.java'

block buffered
src Buffered.java buffering.md
on 'java Buffered.java'

block layers
src Layers.java buffering.md
on 'java Layers.java'

block leak
src Leak.java closing.md
on '(ulimit -n 64; java Leak.java)'

block noleak
src NoLeak.java closing.md
on '(ulimit -n 64; java NoLeak.java)'

block stdin
src WordCount.java standard-streams.md
on 'java WordCount.java < shelf.txt'
on "printf 'the hobbit\nthere and back again\n' | java WordCount.java"
on 'java WordCount.java < /dev/null'
on 'java WordCount.java < /dev/null 2> errors.txt'
on 'cat errors.txt'
