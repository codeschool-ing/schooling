#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of java-functional, as a script that
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

at fp/streams
src Book.java what-a-stream-is.md
src Shelf.java what-a-stream-is.md

block loop
src LoopAndStream.java what-a-stream-is.md
on 'java LoopAndStream.java'

block sources
src Sources.java sources.md
lab exec "$DIR" 'java Sources.java' 2>&1

block lazy
src Lazy.java nothing-until-the-end.md
on 'java Lazy.java'

block once
src Once.java used-once.md
on 'java Once.java'
