#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of cryptography, as a script that
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
# key pairs are derived from labels by vlab/keys.py, so that the transcripts
# repeat; a real key pair comes from `openssl genpkey`, which the lesson
# shows but whose output is not quoted, because it is different every time.
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

block two-keys
on 'ls keys/rsa-2048.* keys/p256.* keys/ed25519-ana.*'
on 'cat keys/ed25519-ana.pub'
on 'openssl pkey -in keys/ed25519-ana.key -pubout | cmp - keys/ed25519-ana.pub && echo "derived from the private key: identical"'
on 'openssl pkey -pubin -in keys/ed25519-ana.pub -noout -text'

block rsa
on 'vcrypt toyrsa 65'
on 'openssl pkey -in keys/rsa-2048.key -noout -text | grep -E "^[A-Za-z]"'
on 'openssl rsa -pubin -in keys/rsa-2048.pub -noout -modulus | cut -c1-72'

block elliptic-curves
on 'openssl pkey -in keys/p256.key -noout -text'

block key-size
on 'for k in rsa-2048 rsa-3072 p256 ed25519-ana; do printf "%-12s %4s bytes\n" $k $(openssl pkey -pubin -in keys/$k.pub -outform DER | wc -c); done'
on 'for k in rsa-2048 rsa-3072; do openssl dgst -sha256 -sign keys/$k.key -out $k.sig data/referral.txt; done'
on 'openssl pkeyutl -sign -rawin -inkey keys/ed25519-ana.key -in data/referral.txt -out ed25519-ana.sig'
on 'wc -c rsa-2048.sig rsa-3072.sig ed25519-ana.sig'
