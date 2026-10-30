#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of mobile-delivery, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash captures.sh > out.txt
#
# It needs lab.sh's machine and lesson 1's ~/planner. expiry.ts is taken from
# the lesson by lab/extract.py, so the program the transcript ran is the one
# it prints.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The three certificates are made by OpenSSL on the recording machine and
#     named after kinds Apple issues. None was issued by Apple. OpenSSL dates
#     a certificate from the moment it is made, so the dates printed below are
#     those of the day the capture ran, and the prose quotes none of them.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'rm -rf ~/planner/certs ~/planner/expiry.ts'

block makecerts
LAB as 'mkdir -p ~/planner/certs'
run $P/certs 'openssl req -x509 -newkey rsa:2048 -nodes -keyout dev.key -out apple-development.pem -days 200 -subj "/CN=Apple Development: Ana Souza (stand-in)" 2>/dev/null'
run $P/certs 'openssl req -x509 -newkey rsa:2048 -nodes -keyout dist.key -out apple-distribution.pem -days 21 -subj "/CN=Apple Distribution: Study Planner (stand-in)" 2>/dev/null'
run $P/certs 'openssl req -x509 -newkey rsa:2048 -nodes -keyout push.key -out apple-push.pem -days 380 -subj "/CN=Apple Push Services: com.example.planner (stand-in)" 2>/dev/null'
run $P/certs 'ls'

block expiry
put watching-the-expiry.md expiry.ts $P/expiry.ts
run $P 'node expiry.ts certs; echo "exit status $?"'
run $P 'node expiry.ts certs 2027-06-01'
