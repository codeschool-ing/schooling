#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of cryptography, as a script that
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
# including keys/webhook.hex, the secret Vereda shares with its payment
# gateway, and data/webhooks/, four deliveries the lab signed as the gateway
# would: evt-2's body was altered after signing, evt-3 is evt-1 delivered
# again a day later, and evt-4 was signed with a key that is not the
# gateway's. keys/ana_ssh is Ana's Ed25519 key in OpenSSH's format, and
# data/allowed_signers names it. The receiver's clock is passed as --now,
# the lab's present (2026-06-15 12:00 in Sao Paulo).
#
# Recorded with OpenSSL 3.0.13, OpenSSH 9.6, Python 3.13 and cryptography 50,
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
