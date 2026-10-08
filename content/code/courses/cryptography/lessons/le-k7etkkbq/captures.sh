#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of cryptography, as a script that
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
# The three servers are started by section `plaintext`'s own commands, which
# write keys/sftp_host_ed25519 with `vcrypt sshkey` and run
# bin/protocol-servers, shown whole in that section, before the first block;
# the script stops them after the last. It must run as root, because the
# servers' script starts sshd, adds a local user `ana` whose only authorised
# key is keys/ana_ssh.pub, and maps files.vereda.example and
# ldap.vereda.example to 127.0.0.1 in /etc/hosts.
#
#   2121  an FTP server (pyftpdlib), account `scheduler`, serving data/release
#   2222  OpenSSH's sshd with internal-sftp, host key keys/sftp_host_ed25519
#   3389  OpenLDAP's slapd, plain LDAP with StartTLS, refusing simple binds
#         without TLS (`security simple_bind=128`)
#   6636  the same slapd over LDAPS, certificate pki/ldap-chain.pem
#
# The FTP password and the directory's admin password are the lab's own.
# libldap checks the directory's certificate against the real clock, which
# is why pki/ldap.pem runs to 2030 (tools/pki.py says so too).
#
# Recorded on Ubuntu 24.04 with OpenSSL 3.0.13, OpenSSH 9.6, OpenLDAP 2.6.10,
# curl 8.5, Ubuntu's pyftpdlib 1.5.9 and Python 3.12, TZ=America/Sao_Paulo.

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


# The servers, started by the lesson's own commands (section `plaintext`),
# which run bin/protocol-servers as the lesson shows it.
bash "$here/../../lab.sh" steps le-k7etkkbq plaintext >/dev/null
B='-D cn=admin,dc=vereda,dc=example -w directory-admin-lab'

block plaintext
on "curl -sv --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (USER|PASS|RETR|230)|^Vereda'"
on "curl -sv --ssl-reqd --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (AUTH|USER|PASS|5)|^curl:'; echo \"exit status \${PIPESTATUS[0]}\""

block sftp
on 'ssh-keygen -lf keys/sftp_host_ed25519'
on 'ssh-keyscan -p 2222 files.vereda.example 2>/dev/null | ssh-keygen -lf -'
on 'ssh-keyscan -p 2222 files.vereda.example 2>/dev/null > known_hosts'
on "echo 'ls /etc/hostname' | sftp -b - -i keys/ana_ssh -P 2222 -o UserKnownHostsFile=known_hosts -o StrictHostKeyChecking=yes ana@files.vereda.example"
on "ssh -v -i keys/ana_ssh -p 2222 -o UserKnownHostsFile=known_hosts -o StrictHostKeyChecking=yes ana@files.vereda.example true 2>&1 | grep -E 'kex: algorithm|kex: client->server|Server host key|matches|Authenticated to'"

block starttls
on "echo | openssl s_client -connect ldap.vereda.example:3389 -starttls ldap -CAfile pki/root.pem -verify_hostname ldap.vereda.example 2>&1 | grep -E '^(New|Verif)'"

block ldap
on "ldapwhoami -x -H ldap://ldap.vereda.example:3389 $B"
on "LDAPTLS_CACERT=pki/root.pem ldapwhoami -x -ZZ -H ldap://ldap.vereda.example:3389 $B"
on "LDAPTLS_CACERT=pki/root.pem ldapwhoami -x -H ldaps://ldap.vereda.example:6636 $B"
on "ldapwhoami -x -H ldaps://ldap.vereda.example:6636 $B"

bin/protocol-servers stop
