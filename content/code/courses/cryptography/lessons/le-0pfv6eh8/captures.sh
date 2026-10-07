#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of cryptography, as a script that
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
# including pki/, Vereda's certificate authority, which vlab/pki.py builds
# with fixed keys and fixed dates (it lists every certificate). Every check
# passes -attime 1781535600, the lab's present: 2026-06-15 12:00 in Sao
# Paulo. The count of Mozilla roots is whatever the recording machine's
# ca-certificates package carried, and yours may differ.
#
# Recorded with OpenSSL 3.0.13, Python 3.13, cryptography 50 and Ubuntu
# 24.04's ca-certificates,
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

block third-party
on 'openssl x509 -in pki/portal.pem -noout -subject -issuer'
on 'openssl x509 -in pki/portal.pem -noout -pubkey'
on 'openssl x509 -in pki/portal.pem -noout -pubkey | cmp - <(openssl pkey -in pki/portal.key -pubout) && echo "the certificate carries the public half of portal.key"'

block hierarchy
on 'for c in root issuing1 portal; do openssl x509 -in pki/$c.pem -noout -subject -issuer; echo; done'
on 'openssl x509 -in pki/root.pem -noout -ext basicConstraints,keyUsage'
on 'openssl x509 -in pki/issuing1.pem -noout -ext basicConstraints'
on 'openssl x509 -in pki/portal.pem -noout -ext basicConstraints,extendedKeyUsage'
on "openssl verify -attime $T -show_chain -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem"

block trust-stores
on 'ls /usr/share/ca-certificates/mozilla | wc -l'
on 'ls /usr/share/ca-certificates/mozilla | grep -i -E "isrg|digicert_global_root_g2"'
on "openssl verify -attime $T -untrusted pki/issuing1.pem pki/portal.pem"
on "openssl verify -attime $T -CAfile pki/root.pem pki/portal.pem"
on 'openssl x509 -in pki/root.pem -noout -subject -fingerprint -sha256; openssl x509 -in pki/impostor-root.pem -noout -subject -fingerprint -sha256'
on "openssl verify -attime $T -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal-impostor.pem"
on "openssl verify -attime $T -CAfile pki/impostor-root.pem pki/portal-impostor.pem"
