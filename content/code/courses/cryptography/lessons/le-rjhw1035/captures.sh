#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of cryptography, as a script that
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
# including data/portal-secret.yaml and data/scheduler.ini, two
# configuration files the course wrote, each with a password stored encoded
# or obfuscated. The passwords and the accounts are the lab's own.
#
# Recorded with GNU coreutils 9.4, OpenSSL 3.0.13, Python 3.13 and
# cryptography 50,
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



block encoding
on "printf 'ana.lima:Vereda@2026' | base64"
on "echo 'YW5hLmxpbWE6VmVyZWRhQDIwMjY=' | base64 -d; echo"
on "printf 'Vereda' | xxd -p; printf 'Vereda' | base64; printf 'Vereda' | openssl enc -aes-256-cbc -K \$(cat keys/aes-256.hex) -iv \$(cat keys/iv-a.hex) | base64"
on 'cat data/portal-secret.yaml'
on "grep password: data/portal-secret.yaml | awk '{print \$2}' | base64 -d; echo"

block obfuscation
on 'cat data/scheduler.ini'
on "grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d; echo"
on "grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d | tr 'A-Za-z' 'N-ZA-Mn-za-m'; echo"

block the-test
on "printf 'V-db-s3cret-2026' > db-password.txt; vcrypt seal --key keys/aes-256.hex --nonce 0000000000000000000000d1 db-password.txt db-password.gcm"
on 'base64 -w0 db-password.gcm; echo'
on 'base64 -w0 db-password.gcm | base64 -d | od -c | head -2'
on 'vcrypt open --key keys/aes-256.hex db-password.gcm; echo'
