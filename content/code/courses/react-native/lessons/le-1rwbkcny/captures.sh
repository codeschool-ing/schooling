#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js installed, as lesson 1 of
# `javascript` leaves the student's computer.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - create-expo-app's report and `expo export`'s go to /dev/null in the
#     transcript: both draw a spinner and characters the interface has no
#     glyph for. `ls` and `find` show what they wrote.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
A=/home/ana/hello

block check
run /home/ana 'node --version'
run /home/ana 'npm --version'
run /home/ana 'git --version'

block hello
run /home/ana 'npx create-expo-app@5.0.0 hello --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1'
run /home/ana 'cd hello'
run $A 'ls'
run $A 'npm install'

block export
run $A 'npx expo export --platform android > /dev/null 2>&1'
run $A 'find dist -type f'
run $A 'file dist/_expo/static/js/android/*.hbc'
run $A 'grep -c "Open up App.tsx" dist/_expo/static/js/android/*.hbc'
