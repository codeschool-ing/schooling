#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of java-functional, as a script that
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
# The balances of Overdraft.java and the addresses in the thread dump change
# from run to run; the lesson quotes one run of this script, on 4
# processors. The deadlocked program is started in the background and
# stopped with kill, as the transcript shows.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/locks

block overdraft
src Overdraft.java race-conditions.md
on 'java Overdraft.java'

block synced
src Synced.java synchronized.md
lab exec "$DIR" 'java Synced.java' 2>&1

block trylock
src TryLock.java the-lock-interface.md
on 'java TryLock.java'

block deadlock
src Deadlock.java deadlock.md
on 'java Deadlock.java > /dev/null &'
quiet 'sleep 5'
on 'jcmd | grep Deadlock'
# ana reads the process id off the line above and types it; the script reads
# it the same way.
pid=$(lab exec "$DIR" 'jcmd' | awk '/Deadlock.java/ {print $1}')
on "jcmd $pid Thread.print | grep -A 16 'Found one'"
on "kill $pid"

block ordered
src Ordered.java deadlock.md
on 'java Ordered.java'
