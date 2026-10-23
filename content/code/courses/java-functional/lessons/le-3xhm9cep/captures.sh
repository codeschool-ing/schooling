#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of java-functional, as a script that
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
# The order in which the pool threads print and the timings change from run
# to run; the lesson quotes one run of this script, on 4 processors.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/executors

block pool
src Pool.java executors.md
on 'java Pool.java'

block futures
src Futures.java futures.md
on 'java Futures.java'

block bounded
src Bounded.java sizing-a-pool.md
on 'java Bounded.java'

block page
src Page.java completable-future.md
lab exec "$DIR" 'java Page.java' 2>&1
