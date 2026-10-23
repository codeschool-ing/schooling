#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of java-functional, as a script that
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

at fp/time

block moment
src Moment.java instants-and-zones.md
on 'java Moment.java'

block spans
src Spans.java periods-and-durations.md
on 'java Spans.java'

block formats
src Formats.java formatting-and-parsing.md
on 'java Formats.java'

block loans
src Loans.java the-clock.md
on 'java Loans.java'
