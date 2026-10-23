#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of java-functional, as a script that
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
# Maven project needs Maven Central; the first build downloads Jackson and the
# pinned plugins into ~ana/.m2, and the transcripts are of the builds after it.
#
# Recorded on Ubuntu 24.04 with openjdk-25-jdk 25.0.4.1+1-1~24.04.4,
# Maven 3.8.7, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

at fp/serial

block shelve
src Shelve.java java-serialisation.md
on 'java Shelve.java'
on "tr -c '[:print:]' . < books.ser; echo"

block filter
src Filter.java reading-untrusted-bytes.md
on 'java Filter.java'

at catalogue
src pom.xml json-with-jackson.md
src src/main/java/com/example/catalogue/Book.java json-with-jackson.md src/main/java/com/example/catalogue/Book.java
src src/main/java/com/example/catalogue/App.java json-with-jackson.md src/main/java/com/example/catalogue/App.java
src src/main/java/com/example/catalogue/Input.java json-from-outside.md src/main/java/com/example/catalogue/Input.java
quiet 'mvn -B -q compile'

block app
on 'mvn -q compile exec:java'

block input
on 'mvn -q compile exec:java -Dexec.mainClass=com.example.catalogue.Input'
