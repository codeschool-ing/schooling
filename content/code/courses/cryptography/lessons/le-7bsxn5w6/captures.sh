#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of cryptography, as a script that
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
# What the lesson's own commands make, which lab.sh reset runs:
#
#   - portal/, section `keys-in-code`: a git repository of two commits with
#     fixed authors and dates, so that its hashes are the same on every run.
#     The first commit writes the lab's webhook key into settings.py; the
#     second replaces it with a read from the environment. The key is the
#     lab's own, derived from a public label, and verifies nothing outside
#     the lab;
#   - export/, section `nonce-reuse`: fourteen days of an invented agenda
#     sealed with `vcrypt seal` under keys/aes-256.hex, with nonces taken from
#     a counter. On the eighth day the counter is put back to 5, standing in
#     for a restore from an old backup, so days 8 to 10 reuse the nonces of
#     days 5 to 7. That reuse is the mistake the section teaches to detect;
#     nothing here makes any use of it, and the audit reads nothing but the
#     nonces.
#
# homemade.py is the annotated example of section `own-algorithm`, read out
# of it below. Its AES-GCM half draws a random key and random nonces, so it
# prints only comparisons, never the bytes. keys/agenda-2.hex is a fresh
# random key, and export/*.v2 the same days re-sealed under it with random
# nonces; those bytes differ on every run and the transcript only reports
# that no nonce repeats.
#
# Recorded on Ubuntu 24.04 with Python 3.12, cryptography 50.0.2 and git 2.43,
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

# portal/ and export/ are made by the lesson's own commands (sections
# `keys-in-code` and `nonce-reuse`), which lab.sh reset has already run.
# homemade.py is the annotated example of section `own-algorithm`, read out
# of it the way its copy button hands it over.
python3 - "$here/own-algorithm.md" > homemade.py <<'PY'
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
blocks = [json.loads(b) for b in re.findall(r"^```schooling-example\n(.*?)^```$", text, re.S | re.M)]
ex = [b for b in blocks if b.get("file") == "homemade.py"]
if len(ex) != 1:
    sys.exit(f"own-algorithm.md has {len(ex)} examples of homemade.py, and this script needs one")
sys.stdout.write("\n".join(p["code"] for p in ex[0]["parts"]) + "\n")
PY

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
