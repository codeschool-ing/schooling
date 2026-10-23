#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of java-functional, as a script that
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

at fp/references

block refs
src References.java four-kinds.md
lab exec "$DIR" 'java References.java' 2>&1

block unbound
src Unbound.java bound-and-unbound.md
on 'java Unbound.java'

block bound
src Bound.java bound-and-unbound.md
on 'java Bound.java'

block ctors
src Constructors.java constructors.md
on 'java Constructors.java'

block ambiguous
src Ambiguous.java when-a-lambda-reads-better.md
on 'javac -d out Ambiguous.java'
