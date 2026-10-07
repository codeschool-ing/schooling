#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of cryptography, as a script that
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
# data/release/ is what section `promises` makes: a stand-in for a software
# release, 20,480 bytes from `vcrypt derive --raw`, a note, and the
# SHA256SUMS file computed for them.
#
# Recorded on Ubuntu 24.04 with OpenSSL 3.0.13, GNU coreutils 9.4, Python 3.12
# and cryptography 50.0.2, TZ=America/Sao_Paulo.

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
