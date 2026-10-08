#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of cryptography, as a script that
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
# pki/ is what lesson 8 makes with `vcrypt pki`: Vereda's certificate
# authority, from tools/pki.py, with fixed keys and fixed dates (pki.py lists
# every certificate). Every check passes -attime 1781535600, the lab's
# present: 2026-06-15 12:00 in Sao Paulo, except where a command passes
# another instant on purpose.
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
