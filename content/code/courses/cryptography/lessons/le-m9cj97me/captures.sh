#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of cryptography, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, as root:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/lab with `lab.sh reset le-m9cj97me`, which writes the tools
# out of the lessons' own fences and runs the commands of section `the-lab`,
# and stops there, in the home of a user `ana` (LAB_HOME moves it). It prints
# each command after a prompt, ana@lab:~/lab$, followed by what it printed.
#
# The keys come from tools/drbg.py, which the lesson shows, and the IVs and
# nonces are fixed in the commands below, both so that the transcripts
# repeat; the lesson says why a real IV is never written down like this.
#
# Block `setup-fails` breaks the lab on purpose and puts it back: it removes
# Ubuntu's python3.12-venv for one command and installs it again, so it needs
# apt to reach Ubuntu's archive.
#
# Recorded on Ubuntu 24.04 with OpenSSL 3.0.13, Python 3.12, cryptography
# 50.0.2 and bcrypt 5.0.0, TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export LAB_HOME=${LAB_HOME:-/home/ana}
export HOME=$LAB_HOME
bash "$here/../../lab.sh" reset le-m9cj97me >/dev/null   # the lab at the end of lesson 1
cd "$HOME/lab"
# What the three lines section `the-lab` adds to ~/.bashrc do.
export PATH=$HOME/lab/venv/bin:$HOME/lab/bin:$PATH VIRTUAL_ENV=$HOME/lab/venv
on() { printf 'ana@lab:~/lab$ %s\n' "$*"; bash -c "$*" 2>&1; }
at() { printf 'ana@lab:%s$ %s\n' "$1" "$2"; (cd "${1/#\~/$HOME}" && bash -c "$2" 2>&1); }
block() { printf '##### %s\n' "$1"; }
# tty DIR SHOWN [PATH]: SHOWN typed into an interactive bash in a
# pseudo-terminal, which is what a person sees, with no ~/.bashrc read; the
# lab's PATH unless another is given.
tty() { printf 'ana@lab:%s$ %s\n' "$1" "$2"
        (cd "${1/#\~/$HOME}" && env -i HOME="$HOME" PATH="${3:-$PATH}" TERM=dumb LC_ALL=C.UTF-8 \
           script -qec "bash --norc -i -c $(printf %q "$2")" /dev/null | tr -d '\r'); }
STOCK=/usr/local/lib/cryptography-stock   # lab.sh points its python3 at 3.12

block the-lab
at '~' 'openssl version'
at '~' 'python3 --version'
at '~' "python3 -c 'import cryptography, bcrypt; print(cryptography.__version__, bcrypt.__version__)'"
at '~' 'cd ~/lab'
on 'sha256sum keys/* data/*'
on 'du -sh ~/lab'

block setup-fails
# 1. python3-venv missing: what a fresh Ubuntu Server says.
mv venv venv.real
apt-get remove -y -q python3.12-venv >/dev/null 2>&1
tty '~' 'python3 -m venv ~/lab/venv' "$STOCK:/usr/bin:/bin"
apt-get install -y -q python3.12-venv >/dev/null 2>&1
tty '~' 'python3 -m venv ~/lab/venv && echo created' "$STOCK:/usr/bin:/bin"
rm -rf venv; mv venv.real venv
# 2. a terminal opened before the lines in ~/.bashrc: an interactive shell,
#    in a pseudo-terminal, with no ~/.bashrc read.
tty '~' 'vcrypt derive iv-a 16' /usr/bin:/bin
at '~' 'source ~/.bashrc; vcrypt derive iv-a 16'
# 3. chmod +x forgotten.
chmod -x bin/vcrypt
tty '~/lab' 'vcrypt derive iv-a 16'
tty '~/lab' 'chmod +x bin/vcrypt; vcrypt derive iv-a 16'
# 4. a paste that lost its indentation: derive.py with the body of `if raw:` flush left.
cp tools/derive.py /tmp/derive.py.good
sed -i 's/^    sys.stdout.buffer.write(data)$/sys.stdout.buffer.write(data)/' tools/derive.py
on 'vcrypt derive iv-a 16'
cp /tmp/derive.py.good tools/derive.py; rm -f /tmp/derive.py.good
# 5. one space short in the slot records.
cp data/slots.dat /tmp/slots.good
sed -i 's/free     $/free    /' data/slots.dat
on 'sha256sum data/slots.dat; wc -c data/slots.dat'
cp /tmp/slots.good data/slots.dat; rm -f /tmp/slots.good

block one-key
on 'cat data/referral.txt'
on 'cat keys/aes-256.hex'
on 'openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/referral.txt -out referral.enc'
on 'od -An -tx1 -N48 referral.enc'
on 'openssl enc -d -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in referral.enc'
on 'openssl enc -d -aes-256-cbc -K $(cat keys/aes-256-b.hex) -iv $(cat keys/iv-a.hex) -in referral.enc -out wrong.txt 2>err.txt; echo "exit status $?"; head -1 err.txt'

block blocks
on 'wc -c data/referral.txt referral.enc'
on 'vcrypt blocks data/slots.dat | head -6'
on 'openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | wc -c'

block modes
on 'vcrypt blocks --letters data/slots.dat'
on 'openssl enc -aes-256-ecb -K $(cat keys/aes-256.hex) -in data/slots.dat | vcrypt blocks --letters -'
on 'openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -'
on 'openssl enc -aes-256-ctr -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -'

block the-iv
on 'for iv in iv-a iv-a iv-b; do openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/$iv.hex) -in data/referral.txt | sha256sum; done'

block authenticated
on 'vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000001 data/slots.dat slots.gcm'
on 'vcrypt open --key keys/aes-256.hex slots.gcm | head -3'
on 'vcrypt flip slots.gcm 18'
on 'vcrypt open --key keys/aes-256.hex slots.gcm | head -3; echo "exit status ${PIPESTATUS[0]}"'
on 'vcrypt seal --key keys/aes-256.hex --nonce 000000000000000000000002 --aad patient=4471 data/referral.txt referral.gcm'
on 'vcrypt open --key keys/aes-256.hex --aad patient=4471 referral.gcm | head -1'
on 'vcrypt open --key keys/aes-256.hex --aad patient=5120 referral.gcm; echo "exit status $?"'
