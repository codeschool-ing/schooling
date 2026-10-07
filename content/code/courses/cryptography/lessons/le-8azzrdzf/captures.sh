#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of cryptography, as a script that
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
# X25519 pairs of Ana and Bruno are derived from labels, so the shared
# secret repeats; `vcrypt ephemeral` draws fresh pairs on every run and
# prints only what does not change. `vcrypt kem` derives its ML-KEM key from
# a label, but encapsulation is randomised, so it prints sizes and a match,
# never the secret. In the forward-secrecy block, recorded.rsa stands for a
# session key captured off the network a year before the server's private
# key leaked; both files are the lab's own.
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


block the-exchange
on 'vcrypt toydh'

block x25519
on 'cat keys/x25519-ana.pub keys/x25519-bruno.pub'
on 'openssl pkeyutl -derive -inkey keys/x25519-ana.key -peerkey keys/x25519-bruno.pub | xxd -p -c 32'
on 'openssl pkeyutl -derive -inkey keys/x25519-bruno.key -peerkey keys/x25519-ana.pub | xxd -p -c 32'
on 'openssl kdf -keylen 32 -kdfopt digest:SHA256 -kdfopt info:vereda-session -kdfopt hexkey:$(openssl pkeyutl -derive -inkey keys/x25519-ana.key -peerkey keys/x25519-bruno.pub | xxd -p -c 32) HKDF'

block forward-secrecy
on 'xxd -r -p keys/aes-256-b.hex | openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -out recorded.rsa; vcrypt seal --key keys/aes-256-b.hex --nonce 0000000000000000000000c7 data/referral.txt recorded.gcm'
on 'openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in recorded.rsa | xxd -p -c 32 > leaked.hex; vcrypt open --key leaked.hex recorded.gcm | head -1'
on 'vcrypt ephemeral'

block post-quantum
on 'vcrypt kem'
on 'openssl pkey -pubin -in keys/x25519-ana.pub -noout -text'
