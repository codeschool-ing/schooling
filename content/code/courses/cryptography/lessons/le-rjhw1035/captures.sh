#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of cryptography, as a script that
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
# data/portal-secret.yaml and data/scheduler.ini are what sections `encoding`
# and `obfuscation` write: two configuration files the course wrote, each
# with a password stored encoded or obfuscated. The passwords and the
# accounts are the lab's own.
#
# Recorded on Ubuntu 24.04 with GNU coreutils 9.4, OpenSSL 3.0.13, Python 3.12
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



block encoding
on "printf 'ana.lima:Vereda@2026' | base64"
on "echo 'YW5hLmxpbWE6VmVyZWRhQDIwMjY=' | base64 -d; echo"
on "printf 'Vereda' | xxd -p; printf 'Vereda' | base64; printf 'Vereda' | openssl enc -aes-256-cbc -K \$(cat keys/aes-256.hex) -iv \$(cat keys/iv-a.hex) | base64"
on "grep password: data/portal-secret.yaml | awk '{print \$2}' | base64 -d; echo"

block obfuscation
on "grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d; echo"
on "grep '^password' data/scheduler.ini | cut -d' ' -f3 | base64 -d | tr 'A-Za-z' 'N-ZA-Mn-za-m'; echo"

block the-test
on "printf 'V-db-s3cret-2026' > db-password.txt; vcrypt seal --key keys/aes-256.hex --nonce 0000000000000000000000d1 db-password.txt db-password.gcm"
on 'base64 -w0 db-password.gcm; echo'
on 'base64 -w0 db-password.gcm | base64 -d | od -c | head -2'
on 'vcrypt open --key keys/aes-256.hex db-password.gcm; echo'
