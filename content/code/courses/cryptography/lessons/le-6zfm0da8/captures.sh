#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of cryptography, as a script that
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
# disk.pass, recovery.pass and the database are what section `luks` makes:
# the two passphrases in files, and, in the local PostgreSQL 16 cluster, a
# database `vereda` owned by a role `ana` with the pgcrypto extension. The
# script runs that section's commands (it must run as root, for
# `sudo -iu postgres`) and reaches the database through PGHOST, PGUSER,
# PGDATABASE and PGPASSWORD, set as the section's `export` line sets them.
# disk.img, a 32 MiB file standing in for a laptop's disk, is made by the
# commands of the luks block.
#
# The LUKS volume is formatted with a fixed UUID and fixed Argon2id costs,
# so that its header prints the same way every time; its salts are random
# and are filtered out. The volume is never opened: mapping it needs the
# kernel's device mapper, which the recording machine does not offer, so
# the passphrases are checked with --test-passphrase, which unlocks the
# volume key without mapping anything. Both passphrases are the lab's own.
#
# The CPF in the column block, 111.444.777-35, is the example number used in
# documentation, with valid check digits; it is not anybody's.
#
# Recorded on Ubuntu 24.04 with cryptsetup 2.7.0, PostgreSQL 16 and GNU
# binutils' strings, TZ=America/Sao_Paulo.

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


# No systemd here to start the cluster, as installing PostgreSQL does on the
# student's machine; and whatever an earlier run left is dropped first.
pg_ctlcluster 16 main start >/dev/null 2>&1
su postgres -c "psql -q" >/dev/null 2>&1 <<'SQL'
DROP DATABASE IF EXISTS vereda;
DROP ROLE IF EXISTS ana;
SQL
# The passphrases and the database, by section `luks`'s own commands.
bash "$here/../../lab.sh" steps le-6zfm0da8 luks
export PGHOST=127.0.0.1 PGUSER=ana PGDATABASE=vereda PGPASSWORD=lab-only-db-password
LUKS='--pbkdf argon2id --pbkdf-force-iterations 4 --pbkdf-memory 65536 --pbkdf-parallel 1'

block luks
on 'truncate -s 32M disk.img'
on "cryptsetup luksFormat -q --type luks2 --cipher aes-xts-plain64 --key-size 512 $LUKS --uuid 6d2f4a1e-0b7c-4c3e-9a51-2f6e8c1d0a37 --key-file disk.pass disk.img"
on "cryptsetup luksAddKey -q $LUKS --key-file disk.pass disk.img recovery.pass"
on "cryptsetup luksDump disk.img | grep -E '^(Version|UUID)|^  [0-9]: |cipher:|Cipher key|PBKDF|Time cost|Memory'"
on 'cryptsetup open --test-passphrase --key-file recovery.pass disk.img && echo "recovery passphrase unlocks the volume key"'
on "printf 'Correct horse battery staple' > typo.pass; cryptsetup open --test-passphrase --key-file typo.pass disk.img; echo \"exit status \$?\""

block column
on "psql -c 'CREATE TABLE patients (id int PRIMARY KEY, name text, cpf bytea)'"
on "psql -c \"INSERT INTO patients VALUES (1, 'Marina Duarte', encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'aes')), (2, 'Joao Pires', encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'aes'))\""
on "psql -c 'SELECT id, name, encode(cpf, '\''hex'\'') FROM patients'"
on "psql -c \"SELECT id, convert_from(decrypt(cpf, 'k-lab-0123456789abcdef0123456789', 'aes'), 'UTF8') FROM patients WHERE id = 1\""
on "psql -c \"UPDATE patients SET cpf = pgp_sym_encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'cipher-algo=aes256')\""
on "psql -c 'SELECT count(*) AS rows, count(DISTINCT cpf) AS distinct_values FROM patients'"
on "psql -c \"SELECT id, pgp_sym_decrypt(cpf, 'k-lab-0123456789abcdef0123456789') FROM patients\""

block database
on 'psql -c CHECKPOINT'
on "sudo strings /var/lib/postgresql/16/main/\$(psql -Atc \"SELECT pg_relation_filepath('patients')\") | grep -oE 'Marina Duarte|Joao Pires|111\\.444\\.777-35' | sort | uniq -c"
