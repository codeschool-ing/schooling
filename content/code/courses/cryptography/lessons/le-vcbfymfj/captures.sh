#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of cryptography, as a script that
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
# wifi_pmk.py is the annotated example of section `psk`; this script reads
# it out of the section, as the example's copy button hands it over, and
# runs it.
#
# No radio is involved. Nothing here joins, observes or tests a wireless
# network: wpa_passphrase and the Python file only compute, from a network
# name and a passphrase the lab made up, the key a network configured with
# them would use. The passphrase is the lab's own and protects nothing.
#
# wpa_passphrase separates its lines with tabs, and the transcripts keep them.
#
# Recorded on Ubuntu 24.04 with wpa_supplicant 2.10 and Python 3.12,
# TZ=America/Sao_Paulo.

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

# wifi_pmk.py is the annotated example in section `psk`, read out of it the
# way its copy button hands it over: the parts' code, one after the other.
python3 - "$here/psk.md" > wifi_pmk.py <<'PY'
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
blocks = re.findall(r"^```schooling-example\n(.*?)^```$", text, re.S | re.M)
ex = [json.loads(b) for b in blocks if json.loads(b).get("file") == "wifi_pmk.py"]
if len(ex) != 1:
    sys.exit(f"psk.md has {len(ex)} examples of wifi_pmk.py, and this script needs one")
sys.stdout.write("\n".join(p["code"] for p in ex[0]["parts"]) + "\n")
PY

block psk
on "wpa_passphrase Vereda-Recepcao 'sala de espera, cadeira azul 2026'"
on "wpa_passphrase Vereda-Equipe 'sala de espera, cadeira azul 2026'"
on "wpa_passphrase Vereda-Recepcao 'vereda1'; echo \"exit status \$?\""
on "python3 wifi_pmk.py 'sala de espera, cadeira azul 2026' Vereda-Recepcao Vereda-Equipe"
