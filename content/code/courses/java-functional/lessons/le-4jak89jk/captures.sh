#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of java-functional, as a script that
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
# timings of Backtrack.java change from run to run; the lesson quotes one run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/regex

block lines
src Lines.java patterns-and-matchers.md
on 'java Lines.java'

block tidy
src Tidy.java replacing-and-splitting.md
on 'java Tidy.java'

block backtrack
src Backtrack.java backtracking.md
on 'java Backtrack.java'

block search
src Search.java text-from-outside.md
on 'java Search.java'
