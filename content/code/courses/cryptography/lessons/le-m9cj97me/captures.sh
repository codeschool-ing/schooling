#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of cryptography, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/lab with lab.sh reset under its own HOME, so nothing of yours
# is touched, and prints each command after a prompt, ana@lab:~/lab$,
# followed by what it printed.
#
# What is STAGED rather than typed: the whole of ~/lab, built by lab.sh. The
# keys come from vlab/drbg.py and the IVs and nonces are fixed in the
# commands below, both so that the transcripts repeat; the lesson says why a
# real IV is never written down like this.
#
# Recorded with OpenSSL 3.0.13, Python 3.13 and cryptography 50,
# TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/var/tmp/cryptography}
mkdir -p "$HOME"
bash "$here/../../lab.sh" reset >/dev/null
cd "$HOME/lab"
export PATH=$HOME/lab/bin:$PATH
on() { printf 'ana@lab:~/lab$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block one-key
on 'cat data/referral.txt'
on 'cat keys/aes-256.hex'
on 'openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/referral.txt -out referral.enc'
on 'od -An -tx1 -N48 referral.enc'
on 'openssl enc -d -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in referral.enc'
on 'openssl enc -d -aes-256-cbc -K $(cat keys/aes-256-b.hex) -iv $(cat keys/iv-a.hex) -in referral.enc -out wrong.txt 2>err.txt; echo "exit status $?"; head -1 err.txt'

block blocks
on 'wc -c data/referral.txt referral.enc'
on 'vcrypt blocks data/slots.dat | head -6'
on 'openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | wc -c'

block modes
on 'vcrypt blocks --letters data/slots.dat'
on 'openssl enc -aes-256-ecb -K $(cat keys/aes-256.hex) -in data/slots.dat | vcrypt blocks --letters -'
on 'openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -'
on 'openssl enc -aes-256-ctr -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -'

block the-iv
on 'for iv in iv-a iv-a iv-b; do openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/$iv.hex) -in data/referral.txt | sha256sum; done'

block authenticated
on 'vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000001 data/slots.dat slots.gcm'
on 'vcrypt open --key keys/aes-256.hex slots.gcm | head -3'
on 'vcrypt flip slots.gcm 18'
on 'vcrypt open --key keys/aes-256.hex slots.gcm | head -3; echo "exit status ${PIPESTATUS[0]}"'
on 'vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000002 --aad patient=4471 data/referral.txt referral.gcm'
on 'vcrypt open --key keys/aes-256.hex --aad patient=4471 referral.gcm | head -1'
on 'vcrypt open --key keys/aes-256.hex --aad patient=5120 referral.gcm; echo "exit status $?"'
