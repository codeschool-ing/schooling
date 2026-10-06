#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of cryptography, as a script that
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
# including data/dns/, Vereda's zone and two Ed25519 DNSSEC keys in BIND's
# format, and pki/ana-mail.* and pki/bruno-mail.*, the S/MIME certificates
# vlab/pki.py issues. The zone is signed with fixed inception and expiry
# dates (2026-06-01 to 2036-06-01) because dnssec-verify reads the real
# clock. Ed25519 and RSA signatures are deterministic, so the transcripts
# repeat; CMS encryption is randomised, so only its structure is printed.
#
# NOT RUN: IPsec. The kernel the course was recorded on does not provide
# the ESP transform to network namespaces, so section 02 is explanation
# and a figure, and says so.
#
# Recorded with OpenSSL 3.0.13, BIND 9.18 and Python 3.13,
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


T=1781535600

block dnssec
on 'cat data/dns/db.vereda.example'
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
