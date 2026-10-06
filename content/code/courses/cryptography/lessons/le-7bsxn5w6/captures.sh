#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of cryptography, as a script that
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
# What is STAGED rather than typed:
#
#   - the whole of ~/lab, built by lab.sh;
#   - portal/, a git repository of two commits with fixed authors and dates,
#     so that its hashes are the same on every run. The first commit writes
#     the lab's webhook key into settings.py; the second replaces it with a
#     read from the environment. The key is the lab's own, derived from a
#     public label, and verifies nothing outside the lab;
#   - homemade.py, which the section shows whole as an annotated example. Its
#     AES-GCM half draws a random key and random nonces, so it prints only
#     comparisons, never the bytes;
#   - export/, fourteen days of an invented agenda sealed with vcrypt under
#     keys/aes-256.hex, with nonces taken from a counter. On the eighth day the
#     counter is put back to 4, standing in for a restore from an old backup,
#     so days 8 to 10 reuse the nonces of days 5 to 7. That reuse is the
#     mistake the section teaches to detect; nothing here makes any use of it,
#     and the audit reads nothing but the nonces;
#   - keys/agenda-2.hex, a fresh random key, and export/*.v2, the same days
#     re-sealed under it with random nonces. Those bytes differ on every run;
#     the transcript only reports that no nonce repeats.
#
# Recorded with Python 3.13, cryptography 50 and git 2.43,
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

# --- portal/: a key committed, then "removed" -------------------------------
export GIT_AUTHOR_NAME="Bruno Reis" GIT_AUTHOR_EMAIL=bruno.reis@vereda.example
export GIT_COMMITTER_NAME="Bruno Reis" GIT_COMMITTER_EMAIL=bruno.reis@vereda.example
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git init -q -b main portal
cat > portal/settings.py <<PY
DATABASE_HOST = "db.vereda.example"
WEBHOOK_KEY = bytes.fromhex("$(cat keys/webhook.hex)")
PY
git -C portal add settings.py
GIT_AUTHOR_DATE="2026-05-04T10:12:00-03:00" GIT_COMMITTER_DATE="2026-05-04T10:12:00-03:00" \
    git -C portal commit -q -m "Verify the payment provider's webhooks"
cat > portal/settings.py <<'PY'
import os

DATABASE_HOST = "db.vereda.example"
WEBHOOK_KEY = bytes.fromhex(os.environ["VEREDA_WEBHOOK_KEY"])
PY
GIT_AUTHOR_DATE="2026-06-10T16:40:00-03:00" GIT_COMMITTER_DATE="2026-06-10T16:40:00-03:00" \
    git -C portal commit -q -am "Read the webhook key from the environment"

# --- homemade.py --------------------------------------------------------------
cat > homemade.py <<'PY'
import hashlib
import os

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

record = b"patient 4471, Marina Duarte, lumbar pain, session 3 of 10"

def homemade(password, text):
    key = hashlib.sha256(password.encode()).digest()
    enc = Cipher(algorithms.AES(key), modes.CBC(bytes(16))).encryptor()
    return enc.update(text + b" " * (-len(text) % 16)) + enc.finalize()

a = homemade("vereda2026", record)
b = homemade("vereda2026", record)
print("homemade, same record twice: ", "identical" if a == b else "different")

key = AESGCM.generate_key(bit_length=256)

def seal(text):
    nonce = os.urandom(12)
    return nonce + AESGCM(key).encrypt(nonce, text, None)

a, b = seal(record), seal(record)
print("AES-GCM, same record twice:  ", "identical" if a == b else "different")

changed = bytearray(a)
changed[20] ^= 1
try:
    AESGCM(key).decrypt(bytes(changed[:12]), bytes(changed[12:]), None)
except InvalidTag:
    print("AES-GCM, one byte changed:    refused")
PY

# --- export/: fourteen days sealed with a counter that was put back ----------
mkdir export
n=1
for d in $(seq -w 1 14); do
    [ "$d" = 08 ] && n=5
    printf 'agenda 2026-06-%s\nroom1 09:00 booked\nroom2 10:30 free\n' "$d" > /tmp/day.txt
    vcrypt seal --key keys/aes-256.hex --nonce "$(printf '%024x' "$n")" /tmp/day.txt "export/agenda-06-$d.gcm" >/dev/null
    n=$((n + 1))
done
rm -f /tmp/day.txt

block repo
on "git -C portal log --oneline"
on "grep -n WEBHOOK portal/settings.py"
on "git -C portal log -p | grep -nE '[0-9a-f]{64}'"
on "git -C portal log --oneline -S \"\$(cat keys/webhook.hex)\""

block homemade
on "python3 homemade.py"

block nonces
on "ls export | head -3; ls export | wc -l"
on "vcrypt nonce-audit export/*.gcm; echo \"exit status \$?\""
on "openssl rand -hex 32 > keys/agenda-2.hex"
on "for f in export/*.gcm; do vcrypt open --key keys/aes-256.hex \$f | vcrypt seal --key keys/agenda-2.hex --nonce \$(openssl rand -hex 12) - \${f%.gcm}.v2 >/dev/null; done"
on "vcrypt nonce-audit export/*.v2"
