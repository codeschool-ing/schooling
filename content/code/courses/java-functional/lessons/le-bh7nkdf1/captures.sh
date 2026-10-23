#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of java-functional, as a script that
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

at fp/files

block names
src Names.java paths.md
on 'java Names.java'

block catalogue
src Catalogue.java reading-and-writing.md
on 'java Catalogue.java'

block tree
src Tree.java walking-a-tree.md
on 'java Tree.java'

block failures
src Failures.java when-it-fails.md
on 'java Failures.java'

block inside
src Inside.java when-it-fails.md
on 'java Inside.java'
