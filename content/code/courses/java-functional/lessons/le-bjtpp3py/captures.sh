#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of java-functional, as a script that
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

at fp/higher-order

block select
src Select.java taking-behaviour.md
on 'java Select.java'

block factories
src Factories.java returning-behaviour.md
lab exec "$DIR" 'java Factories.java' 2>&1

block wrappers
src Wrappers.java wrapping-a-function.md
on 'java Wrappers.java'

block strategies
src Strategies.java rules-by-name.md
on 'java Strategies.java student 8990'
on 'java Strategies.java black-friday 8990'
on 'java Strategies.java free-shipping 12000'
on 'java Strategies.java free-shipping 15000'
on 'java Strategies.java studnet 8990; echo $?'
