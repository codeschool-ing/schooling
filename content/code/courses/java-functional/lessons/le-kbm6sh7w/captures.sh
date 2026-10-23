#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of java-functional, as a script that
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

# The server runs in the background here, where the lesson gives it a terminal
# of its own; its terminal is quoted at the end, from the log it wrote, and it
# is stopped with a signal where the student presses Ctrl+C.
at fp/net

block echo
src Echo.java sockets.md
on 'java Echo.java'

block server-start
src ShelfServer.java an-http-server.md
quiet 'nohup java ShelfServer.java > server.log 2>&1 &'
quiet 'for i in $(seq 150); do (exec 3<>/dev/tcp/127.0.0.1/8080) 2>/dev/null && exit 0; sleep 0.2; done; exit 1'
printf 'ana@vm:~/%s$ %s\n' "$DIR" 'java ShelfServer.java'
lab exec "$DIR" 'cat server.log'

block client
src Client.java an-http-client.md
on 'java Client.java'

block trouble
src Trouble.java when-the-network-fails.md
on 'java Trouble.java'

block server-log
quiet 'sleep 3'
printf 'ana@vm:~/%s$ %s\n' "$DIR" 'java ShelfServer.java'
lab exec "$DIR" 'cat server.log'
quiet 'kill $(jcmd | awk "/ShelfServer/ {print \$1}")'
