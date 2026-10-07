#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of cryptography, as a script that
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
# What is STAGED rather than typed: the whole of ~/lab, built by lab.sh,
# including data/release/, a stand-in for a software release: 20,480 bytes
# derived from a label and a SHA256SUMS file lab.sh computed for it.
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


block promises
on "printf 'Eight sessions' | sha256sum"
on "printf 'Eight session' | sha256sum"
on "vcrypt avalanche 'Eight sessions' 'eight sessions'"
on 'sha256sum data/referral.txt data/slots.dat data/release/portal-2.4.1.tar'
on 'head -c 1000000 /dev/zero | sha256sum'

block sha2-family
on 'for h in md5 sha1 sha256 sha512 sha3-256; do printf "%-9s %s\n" $h $(openssl dgst -$h -r data/referral.txt | cut -d" " -f1); done'
on 'for h in md5 sha1 sha256 sha512 sha3-256; do printf "%-9s %3s bits\n" $h $(( $(openssl dgst -$h -r data/referral.txt | cut -d" " -f1 | tr -d "\n" | wc -c) * 4 )); done'

block choosing
on 'cd data/release && cat SHA256SUMS'
on 'cd data/release && sha256sum -c SHA256SUMS'
on 'cd data/release && printf x >> portal-2.4.1.tar && sha256sum -c SHA256SUMS; echo "exit status $?"'
