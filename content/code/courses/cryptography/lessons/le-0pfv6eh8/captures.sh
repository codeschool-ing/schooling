#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of cryptography, as a script that
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
# pki/ is what section `third-party` makes with `vcrypt pki`: Vereda's
# certificate authority, from tools/pki.py, which the lesson shows, with keys
# from tools/keys.py and fixed dates (pki.py lists every certificate). Every
# check passes -attime 1781535600, the lab's present: 2026-06-15 12:00 in Sao
# Paulo. The count of Mozilla roots is whatever the recording machine's
# ca-certificates package carried, and yours may differ.
#
# Recorded on Ubuntu 24.04 with OpenSSL 3.0.13, Python 3.12, cryptography
# 50.0.2 and Ubuntu 24.04's ca-certificates, TZ=America/Sao_Paulo.

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

block third-party
on 'ls pki'
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
