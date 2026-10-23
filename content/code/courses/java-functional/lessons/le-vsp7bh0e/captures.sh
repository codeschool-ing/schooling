#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of java-functional, as a script that
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
# random values, salts and timings are new on every run.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/secrets

block dice
src Dice.java random-is-a-formula.md
on 'java Dice.java'

block tokens
src Tokens.java secure-random.md
on 'java Tokens.java'

block cost
src Cost.java slow-on-purpose.md
on 'java Cost.java'

block passwords
src Passwords.java storing-and-checking.md
on 'java Passwords.java'
