#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of java-functional, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program it
# runs is taken out of the lesson's own English .md, so the file the student
# copies is the file that ran.
#
#   sudo bash ../../lab.sh setup      # once: OpenJDK 25, Maven and ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana saved, written by src,
# including Book.java and Shelf.java from lesson 6. The two "split up" lines
# of Reduce.java depend on how the stream was split across this machine's 4
# processors.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/streams
src Book.java ../le-g5hpn0fx/what-a-stream-is.md
src Shelf.java ../le-g5hpn0fx/what-a-stream-is.md

block steps
src Steps.java keeping-and-transforming.md
lab exec "$DIR" 'java Steps.java' 2>&1

block reduce
src Reduce.java reduce.md
on 'java Reduce.java'

block answers
src Answers.java the-short-answers.md
on 'java Answers.java'

block collect
src Collect.java collect.md
on 'java Collect.java'
