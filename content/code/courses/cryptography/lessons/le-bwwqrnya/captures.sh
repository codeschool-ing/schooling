#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of cryptography, as a script that
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
# The TLS servers: the script runs section `hello`'s own commands, which
# start openssl s_server four times on 127.0.0.1 before the first block, and
# stops them after the last:
#
#   8443  portal.vereda.example, sending its certificate and the issuing CA
#   8444  the same certificate, without the issuing CA
#   8445  agenda.vereda.example, whose certificate expired on 10 April
#   8446  intranet.vereda.example, self-signed
#
# Every client check passes -attime 1781535600, the lab's present. A trace
# carries fresh random bytes on every connection, so the transcripts pipe it
# through `vcrypt tls-flow`, which the lesson shows, and which keeps the
# message names and the fields the lesson discusses and drops the random
# values.
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
# The four servers, started by the lesson's own commands (section `hello`).
pkill -f 'openssl s_server -accept 127.0.0.1:844' 2>/dev/null; sleep 1
bash "$here/../../lab.sh" steps le-bwwqrnya hello
sleep 1
C="openssl s_client -CAfile pki/root.pem -attime $T -verify_return_error"

block hello
on "echo | $C -connect 127.0.0.1:8443 -servername portal.vereda.example -trace 2>&1 | vcrypt tls-flow"

block keys
on "echo | $C -connect 127.0.0.1:8443 -servername portal.vereda.example -keylogfile session.keys >/dev/null 2>&1; grep -v '^#' session.keys | cut -d' ' -f1 | sort"
on "grep CLIENT_TRAFFIC_SECRET_0 session.keys | awk '{print length(\$3)/2 \" bytes\"}'"

block failures
on "echo | $C -connect 127.0.0.1:8443 -servername portal.vereda.example -verify_hostname portal.vereda.example 2>&1 | grep -E '^Verif'"
on "echo | $C -connect 127.0.0.1:8444 -servername portal.vereda.example -verify_hostname portal.vereda.example 2>&1 | grep -E '^Verif'"
on "echo | $C -connect 127.0.0.1:8445 -servername agenda.vereda.example -verify_hostname agenda.vereda.example 2>&1 | grep -E '^Verif'"
on "echo | $C -connect 127.0.0.1:8443 -servername portal.vereda.example -verify_hostname www.vereda.example 2>&1 | grep -E '^Verif'"
on "echo | $C -connect 127.0.0.1:8446 -servername intranet.vereda.example -verify_hostname intranet.vereda.example 2>&1 | grep -E '^Verif'"
on "echo | $C -connect 127.0.0.1:8445 -servername agenda.vereda.example -trace 2>&1 | vcrypt tls-flow | tail -6"

block versions
on "echo | $C -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_2 -trace 2>&1 | vcrypt tls-flow"
on "echo | $C -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_1 2>&1 | grep -o 'no protocols available\|alert protocol version\|unsupported protocol' | head -1"
on "echo | $C -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_2 -cipher AES256-GCM-SHA384 2>&1 | grep -o 'handshake failure\|no shared cipher\|no ciphers available' | head -1"

pkill -f 'openssl s_server -accept 127.0.0.1:844'
