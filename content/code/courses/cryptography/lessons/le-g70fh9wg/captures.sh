#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of cryptography, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/lab with lab.sh reset, which builds it as the lessons do, in
# the home of a user `ana` (LAB_HOME moves it), and prints each command after
# a prompt, ana@lab:~/lab$, followed by what it printed.
#
# The key pairs are the ones lesson 2 writes with `vcrypt pairs`. In this
# lesson rsa-3072 stands for the key pair of Vereda's records service, and the
# ed25519-ana and ed25519-bruno pairs for two people. RSA-OAEP encryption is
# randomised, so its ciphertexts differ on every run: the script prints their
# sizes and whether they match, never their bytes.
#
# Recorded on Ubuntu 24.04 with OpenSSL 3.0.13, Python 3.12 and cryptography
# 50.0.2, TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export LAB_HOME=${LAB_HOME:-/home/ana}
export HOME=$LAB_HOME
bash "$here/../../lab.sh" reset >/dev/null
cd "$HOME/lab"
# What the three lines lesson 1 adds to ~/.bashrc do.
export PATH=$HOME/lab/venv/bin:$HOME/lab/bin:$PATH VIRTUAL_ENV=$HOME/lab/venv
on() { printf 'ana@lab:~/lab$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block encrypt-to
on 'cat data/referral.txt | wc -c'
on 'openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/referral.txt -out ref1.rsa'
on 'openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/referral.txt -out ref2.rsa'
on 'wc -c ref1.rsa ref2.rsa; cmp -s ref1.rsa ref2.rsa || echo "the two ciphertexts differ"'
on 'openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in ref1.rsa'
on 'openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/slots.dat -out slots.rsa 2>&1 | grep -o "data too large for key size"'

block sign-with
on 'openssl pkeyutl -sign -rawin -inkey keys/ed25519-ana.key -in data/referral.txt -out referral.sig'
on 'od -An -tx1 referral.sig'
on 'openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-ana.pub -in data/referral.txt -sigfile referral.sig'
on 'sed "s/Eight sessions/Twelve sessions/" data/referral.txt > altered.txt'
on 'openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-ana.pub -in altered.txt -sigfile referral.sig'
on 'openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-bruno.pub -in data/referral.txt -sigfile referral.sig'

block hybrid
on 'vcrypt seal --key keys/aes-256-b.hex --nonce 0000000000000000000000a1 data/slots.dat slots.gcm'
on 'xxd -r -p keys/aes-256-b.hex > session.key; wc -c session.key'
on 'openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in session.key -out session.rsa; rm session.key'
on 'wc -c slots.gcm session.rsa'
on 'openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in session.rsa | xxd -p -c 32 > recovered.hex'
on 'vcrypt open --key recovered.hex slots.gcm | head -2'
