#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of cryptography, as a script that
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
# Paulo, except where a command passes another instant on purpose.
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

T=1781535600

block third-party
on 'openssl x509 -in pki/portal.pem -noout -subject -issuer'
T=1781535600

block fields
on 'openssl x509 -in pki/portal.pem -noout -text'

block validity
on 'for c in portal agenda files; do printf "%-7s " $c; openssl x509 -in pki/$c.pem -noout -enddate; done'
on "openssl verify -attime $T -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/agenda.pem"
on 'openssl verify -attime $(date -d "2026-03-01 12:00 -03" +%s) -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/agenda.pem'
on "echo \$(( (\$(date -d \"\$(openssl x509 -in pki/portal.pem -noout -enddate | cut -d= -f2)\" +%s) - $T) / 86400 )) days left on portal.pem"

block names
on 'openssl x509 -in pki/portal.pem -noout -ext subjectAltName'
on "openssl verify -attime $T -verify_hostname portal.vereda.example -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem"
on "openssl verify -attime $T -verify_hostname www.vereda.example -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem"

block revocation
on 'openssl crl -in pki/issuing1.crl -noout -text | head -15'
on "openssl verify -attime $T -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/files.pem"
on "openssl verify -attime $T -crl_check -CRLfile pki/issuing1.crl -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/files.pem"
on 'openssl verify -attime $(date -d "2026-07-15 12:00 -03" +%s) -crl_check -CRLfile pki/issuing1.crl -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem'
on 'openssl x509 -in pki/portal.pem -noout -ext crlDistributionPoints'
