#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of cryptography, as a script that
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
# data/users.csv and keys/pepper.hex are what section `unsalted` makes:
# eight staff accounts with passwords the course wrote, and a pepper from
# `vcrypt derive`. Every salt is derived from a label by tools/passwords.py,
# which the lesson shows, so the stores repeat byte for byte; a real system
# draws each salt at random when it stores the password. Nothing here is a
# real password store, and no password in it is anybody's.
#
# Recorded on Ubuntu 24.04 with Python 3.12, cryptography 50.0.2 and bcrypt
# 5.0.0, TZ=America/Sao_Paulo.

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



block unsalted
on 'cat data/users.csv'
on 'vcrypt store sha256 data/users.csv > store-sha256.txt; head -3 store-sha256.txt'
on 'vcrypt audit store-sha256.txt'
on "printf 'Vereda@2026' | sha256sum"

block salt
on 'vcrypt store salted-sha256 data/users.csv > store-salted.txt; head -3 store-salted.txt'
on 'vcrypt audit store-salted.txt'

block slow
on 'vcrypt store pbkdf2 data/users.csv > store-pbkdf2.txt; head -1 store-pbkdf2.txt'
on 'vcrypt store bcrypt data/users.csv > store-bcrypt.txt; head -1 store-bcrypt.txt'
on 'vcrypt store argon2id data/users.csv > store-argon2.txt; head -1 store-argon2.txt'
on 'vcrypt audit store-argon2.txt'

block pepper
on 'vcrypt store argon2id --pepper keys/pepper.hex data/users.csv > store-peppered.txt; head -1 store-peppered.txt'
on "vcrypt verify --pepper keys/pepper.hex store-peppered.txt ana.lima 'Vereda@2026'"
on "vcrypt verify store-peppered.txt ana.lima 'Vereda@2026'"

block upgrade
on 'vcrypt store argon2id --cost 7168,1,1 data/users.csv > store-old.txt; head -1 store-old.txt'
on "vcrypt verify store-old.txt ana.lima 'Vereda@2026'"
on "vcrypt verify store-old.txt ana.lima 'vereda@2026'"
on "vcrypt verify store-old.txt ana.lim 'Vereda@2026'"
