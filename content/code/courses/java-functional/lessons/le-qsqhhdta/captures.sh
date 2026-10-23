#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of java-functional, as a script that
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
# Which thread did how much, the timings, which runs of Wrong.java lost
# elements or threw, and the order forEach printed in all change from run to
# run; the lesson quotes one run of this script, on 4 processors. Wrong.java
# is run until one run shows a race's three outcomes together, as said below.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/parallel

block who
src WhoWorks.java how-it-splits.md
on 'java WhoWorks.java'

block primes
src Primes.java measuring.md
on 'java Primes.java'

block wrong
src Wrong.java when-it-goes-wrong.md
# A race shows a different face on every run. The lesson describes all three
# (an element lost, an exception, a run that happens to be right), so this
# reruns Wrong.java, unseen, until one run shows all three, at most 30 times,
# and then prints that run as ana typing it once.
for attempt in $(seq 1 30); do
  out=$(lab exec "$DIR" 'java Wrong.java' 2>&1)
  if grep -q 'Exception' <<<"$out" && grep -q '10000 of 10000$' <<<"$(sed -n 1,10p <<<"$out")" \
      && grep -qv '10000 of 10000\|Exception' <<<"$(sed -n 1,10p <<<"$out")"; then
    break
  fi
done
printf 'ana@vm:~/%s$ %s\n%s\n' "$DIR" 'java Wrong.java' "$out"
echo "wrong: attempt $attempt" >&2
