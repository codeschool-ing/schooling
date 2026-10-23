#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of java-functional, as a script that
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

at fp/composition

block compose
src Compose.java andthen-and-compose.md
on 'java Compose.java'

block tests
src Tests.java combining-tests.md
on 'java Tests.java'

block orders
src Orders.java comparators.md
on 'java Orders.java'

block pipeline
src Pipeline.java a-pipeline-of-steps.md
lab exec "$DIR" 'java Pipeline.java' 2>&1
