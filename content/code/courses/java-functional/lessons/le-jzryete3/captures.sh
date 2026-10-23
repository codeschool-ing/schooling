#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of java-functional, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program it
# runs is taken out of the lesson's own English .md, so the file the student
# copies is the file that ran.
#
#   sudo bash ../../lab.sh setup      # once: OpenJDK 25, Maven and ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana saved, written by src,
# including Book.java and Shelf.java from lesson 6.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/streams
src Book.java ../le-g5hpn0fx/what-a-stream-is.md
src Shelf.java ../le-g5hpn0fx/what-a-stream-is.md

block grouping
src Grouping.java grouping.md
on 'java Grouping.java'

block downstream
src Downstream.java what-each-group-holds.md
lab exec "$DIR" 'java Downstream.java' 2>&1

block partition
src Partition.java partitioning.md
on 'java Partition.java'

block finishing
src Finishing.java finishing-and-combining.md
lab exec "$DIR" 'java Finishing.java' 2>&1
