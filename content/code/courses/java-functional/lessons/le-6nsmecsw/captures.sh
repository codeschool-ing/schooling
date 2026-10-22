#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of java-functional, as a script that
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
# The spin count and the Litmus counts change from run to run; the lesson
# quotes one run of this script, on 4 processors (x86-64). Litmus.java is
# run until one run shows the 0,0 outcome, as said below.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/memory

block stop
src Stop.java a-flag-nobody-sees.md
on 'java Stop.java'

block stop-xint
on 'java -Xint Stop.java'

block litmus
src Litmus.java reordering.md
# The outcome the section is about is rare: some runs show none of it. This
# reruns Litmus.java, unseen, until a run shows at least one 0,0, at most 20
# times, and prints that run as ana typing it once.
for attempt in $(seq 1 20); do
  out=$(lab exec "$DIR" 'java Litmus.java' 2>&1)
  grep -q '^r1=0 r2=0: [1-9]' <<<"$out" && break
done
printf 'ana@vm:~/%s$ %s\n%s\n' "$DIR" 'java Litmus.java' "$out"
echo "litmus: attempt $attempt" >&2

block joined
src Joined.java happens-before.md
on 'java Joined.java'

block published
src Published.java safe-publication.md
on 'java Published.java'
