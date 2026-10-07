#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of cryptography, as a script that
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
# What the lesson's own commands set up before the first block:
#
#   - two FreeRADIUS 3.2 servers, started by bin/radius-servers, which section
#     `methods` shows whole (it must run as root). The real one answers on
#     127.0.0.1 with lesson 8's radius.pem and knows the user ana; the other
#     answers on 127.0.0.2 with radius-impostor.pem, which carries the same
#     names and is issued by the impostor root, and knows nobody. Both accept
#     the RADIUS secret lab-only-radius-secret from the loopback network, on
#     IPv4 only;
#   - peap.conf and peap-lax.conf, the two client profiles, which sections
#     `methods` and `validate` write.
#
# eapol_test plays the access point and the laptop at once: it speaks EAP to
# a RADIUS server exactly as an access point relays it, with no radio. Its
# debug output is long and carries the session's random values, so the
# transcripts pass it through `vcrypt eap-log`, which the lesson shows, and
# which keeps the events the lesson discusses and none of the keys; the PMK
# comparison prints only how many different PMKs two sessions produced.
#
# ana's password is the lab's own and protects nothing. Nothing here is
# pointed at a network the lab did not build.
#
# Recorded on Ubuntu 24.04 with FreeRADIUS 3.2.5 and eapol_test from
# wpa_supplicant 2.10, TZ=America/Sao_Paulo.

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

# The two RADIUS servers and the two profiles, by the lesson's own commands:
# section `methods` starts bin/radius-servers, shown whole there, and writes
# peap.conf; section `validate` writes peap-lax.conf. No systemd here, so
# there is no packaged freeradius service to stop first, as the lesson does.
bash "$here/../../lab.sh" steps le-mg9c2snz methods >/dev/null
bash "$here/../../lab.sh" steps le-mg9c2snz validate >/dev/null
sleep 2

block cert
on "openssl x509 -in pki/radius.pem -noout -subject -issuer -ext subjectAltName,extendedKeyUsage"
on "openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/radius.pem"

block peap
on "eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | vcrypt eap-log"
on "for i in 1 2; do eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | grep 'PMK from EAPOL'; done | sort -u | wc -l"

block impostor
on "openssl x509 -in pki/radius-impostor.pem -noout -subject -issuer -ext subjectAltName"
on "eapol_test -c peap.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log"
on "diff peap.conf peap-lax.conf"
on "eapol_test -c peap-lax.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log"

bin/radius-servers stop
