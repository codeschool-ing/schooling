#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of mobile-offline (crypt).
#
#   sudo bash captures.sh > out.txt
#
# Needs lab.sh's machine and lesson 1's ~/planner (data.ts). Works in
# ~/planner/crypt only. crypt.ts is taken from the lesson's schooling-example
# by lab/extract.py, joined as the copy button joins it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - kek.bin, a file, stands in for the Keystore or Keychain; the lesson
#     says so where it shows the program.
#   - "tamper" flips one bit of sessions.enc with a node one-liner, and
#     moves kek.bin away and back to play a phone that lost its key.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/crypt
LAB as 'rm -rf ~/planner/crypt && mkdir -p ~/planner/crypt'
put encrypting-the-data.md crypt.ts $D/crypt.ts

block seal
run $D 'node crypt.ts init'
run $D 'node crypt.ts seal'
run $D 'node crypt.ts seal'
run $D 'node crypt.ts open'
run $D 'grep -c spanish ../data.ts sessions.enc'

block tamper
run $D "node -e \"const fs = require('fs'); const b = fs.readFileSync('sessions.enc'); b[40] ^= 1; fs.writeFileSync('sessions.enc', b)\""
run $D 'node crypt.ts open'
run $D 'node crypt.ts seal'
run $D 'mv kek.bin kek.away'
run $D 'node crypt.ts open'
run $D 'mv kek.away kek.bin'
run $D 'node crypt.ts open'
