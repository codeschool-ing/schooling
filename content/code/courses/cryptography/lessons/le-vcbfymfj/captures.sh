#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of cryptography, as a script that
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
# What is STAGED rather than typed: the whole of ~/lab, built by lab.sh, and
# the file wifi_pmk.py, which the section shows whole as an annotated example
# and this script writes before running it.
#
# No radio is involved. Nothing here joins, observes or tests a wireless
# network: wpa_passphrase and the Python file only compute, from a network
# name and a passphrase the lab made up, the key a network configured with
# them would use. The passphrase is the lab's own and protects nothing.
#
# wpa_passphrase separates its lines with tabs, and the transcripts keep them.
#
# Recorded with wpa_supplicant 2.10 and Python 3.13, TZ=America/Sao_Paulo.

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

cat > wifi_pmk.py <<'PY'
import hashlib
import sys

def pmk(passphrase: str, ssid: str) -> bytes:
    if not 8 <= len(passphrase) <= 63:
        raise ValueError("a WPA passphrase has 8 to 63 characters")
    return hashlib.pbkdf2_hmac("sha1", passphrase.encode(), ssid.encode(), 4096, 32)

passphrase = sys.argv[1]
for ssid in sys.argv[2:]:
    print(f"{ssid:16} {pmk(passphrase, ssid).hex()}")
PY

block psk
on "wpa_passphrase Vereda-Recepcao 'sala de espera, cadeira azul 2026'"
on "wpa_passphrase Vereda-Equipe 'sala de espera, cadeira azul 2026'"
on "wpa_passphrase Vereda-Recepcao 'vereda1'; echo \"exit status \$?\""
on "python3 wifi_pmk.py 'sala de espera, cadeira azul 2026' Vereda-Recepcao Vereda-Equipe"
