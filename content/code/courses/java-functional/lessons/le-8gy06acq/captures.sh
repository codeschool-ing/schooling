#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of java-functional, as a script that
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
# Timings, memory and carrier names change from run to run; the lesson quotes
# one run of this script, on 4 processors and 15 GB of memory. The second run
# of Pinning.java uses the openjdk-21-jdk this machine also has (see lesson
# 1's captures.sh), by its full path, to show the behaviour before Java 24.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/virtual

block virtual
src Virtual.java what-a-virtual-thread-is.md
on 'java Virtual.java'

block million
src Million.java a-million-threads.md
on 'java Million.java'

block throughput
src Throughput.java what-it-changes.md
on 'java Throughput.java'

block limited
src Limited.java the-limits.md
on 'java Limited.java'

block pinning
src Pinning.java the-limits.md
on 'java Pinning.java'
on '/usr/lib/jvm/java-21-openjdk-amd64/bin/java Pinning.java'
