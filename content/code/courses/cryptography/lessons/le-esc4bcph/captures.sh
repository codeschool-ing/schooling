#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of cryptography, as a script that
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
# data/dns/ is what section `dnssec` makes: Vereda's zone, written by a
# heredoc, and its two Ed25519 DNSSEC keys, which `vcrypt dnskeys` derives
# from labels so that the signed zone repeats. The S/MIME certificates are
# lesson 8's, from `vcrypt pki`.
#
# Recorded on Ubuntu 24.04 with BIND 9.18, OpenSSL 3.0.13, Python 3.12 and
# cryptography 50.0.2, TZ=America/Sao_Paulo.

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


T=1781535600

block dnssec
on 'ls data/dns'
on 'cd data/dns && dnssec-signzone -S -K . -s 20260601000000 -e 20360601000000 -o vereda.example -f signed.zone db.vereda.example 2>&1 | tail -5'
on "grep -A6 '^portal' data/dns/signed.zone"
on 'cat data/dns/dsset-vereda.example.'
on "cd data/dns && sed 's/192.0.2.10\$/203.0.113.66/' signed.zone > forged.zone && dnssec-verify -o vereda.example forged.zone 2>&1 | head -1"

block smime
on 'openssl x509 -in pki/ana-mail.pem -noout -subject -ext subjectAltName,extendedKeyUsage'
on 'openssl cms -sign -nodetach -noattr -md sha256 -in data/referral.txt -signer pki/ana-mail.pem -inkey pki/ana-mail.key -certfile pki/issuing1.pem -outform PEM -out referral.p7s; head -3 referral.p7s'
on "openssl cms -verify -inform PEM -in referral.p7s -CAfile pki/root.pem -attime $T -purpose smimesign 2>&1"
on 'openssl cms -encrypt -aes-256-gcm -recip pki/bruno-mail.pem -keyopt rsa_padding_mode:oaep -in data/referral.txt -outform PEM -out referral.p7m'
on "openssl cms -cmsout -print -inform PEM -in referral.p7m | grep -E 'contentType|algorithm:|issuer:|serialNumber'"
on 'openssl cms -decrypt -inform PEM -in referral.p7m -recip pki/bruno-mail.pem -inkey pki/bruno-mail.key | head -1'
on 'openssl cms -decrypt -inform PEM -in referral.p7m -recip pki/ana-mail.pem -inkey pki/ana-mail.key 2>&1 | head -1'
