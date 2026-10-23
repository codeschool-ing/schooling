#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of java-functional, as a script that
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
# StructuredTaskScope is a preview API in Java 25 (JEP 505): the programs
# that use it run with --enable-preview --source 25.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/structured

block orphan
src Orphan.java tasks-that-outlive-their-caller.md
on 'java Orphan.java'

block scoped
src Scoped.java a-scope-for-tasks.md
on 'java --enable-preview --source 25 Scoped.java'
on 'java Scoped.java 2>&1 | head -n 4'

block first
src FirstAnswer.java other-policies-and-the-preview.md
on 'java --enable-preview --source 25 FirstAnswer.java'
