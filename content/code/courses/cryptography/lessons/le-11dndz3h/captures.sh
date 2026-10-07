#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of cryptography, as a script that
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
# keys/webhook.hex and data/webhooks/ are what section `integrity` makes:
# the secret Vereda shares with its payment gateway, and four deliveries
# `vcrypt deliveries` signs as the gateway would (evt-2's body altered after
# signing, evt-3 a replay of evt-1 a day later, evt-4 signed with a key that
# is not the gateway's). keys/ana_ssh and data/allowed_signers are what
# section `signatures` makes. The receiver's clock is passed as --now, the
# lab's present (2026-06-15 12:00 in Sao Paulo).
#
# Recorded on Ubuntu 24.04 with OpenSSL 3.0.13, OpenSSH 9.6, Python 3.12 and
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



block integrity
on 'cat data/webhooks/evt-1.json; echo'
on 'sha256sum data/webhooks/evt-1.json'
on "sed 's/12000/120/' data/webhooks/evt-1.json > forged.json; sha256sum forged.json"

block hmac
on 'openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) data/webhooks/evt-1.json'
on 'openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) forged.json'
on 'openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/aes-256.hex) forged.json'

block webhooks
on 'cat data/webhooks/evt-1.sig'
on "printf '%s.' 1781535558 | cat - data/webhooks/evt-1.json | openssl dgst -sha256 -mac HMAC -macopt hexkey:\$(cat keys/webhook.hex) -r"
on 'vcrypt webhook --key keys/webhook.hex --now 1781535600 data/webhooks/*.json'

block signatures
on 'cat keys/ana_ssh.pub'
on 'cat data/allowed_signers'
on 'ssh-keygen -Y sign -f keys/ana_ssh -n file data/release/NOTES.txt'
on 'cat data/release/NOTES.txt.sig'
on 'ssh-keygen -Y verify -f data/allowed_signers -I ana@vereda.example -n file -s data/release/NOTES.txt.sig < data/release/NOTES.txt'
on "sed 's/SMS/e-mail/' data/release/NOTES.txt | ssh-keygen -Y verify -f data/allowed_signers -I ana@vereda.example -n file -s data/release/NOTES.txt.sig"
