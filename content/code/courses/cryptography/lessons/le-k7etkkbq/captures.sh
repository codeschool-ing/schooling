#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of cryptography, as a script that
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
# three servers this script starts on 127.0.0.1 before the first block and
# stops after the last. It must run as root, because it starts sshd, adds a
# local user `ana` whose only authorised key is keys/ana_ssh.pub, and maps
# files.vereda.example and ldap.vereda.example to 127.0.0.1 in /etc/hosts.
#
#   2121  an FTP server (pyftpdlib), account `scheduler`, serving data/release
#   2222  OpenSSH's sshd with internal-sftp, host key keys/sftp_host_ed25519
#   3389  OpenLDAP's slapd, plain LDAP with StartTLS, refusing simple binds
#         without TLS (`security simple_bind=128`)
#   6636  the same slapd over LDAPS, certificate pki/ldap-chain.pem
#
# The FTP password and the directory's admin password are the lab's own.
# libldap checks the directory's certificate against the real clock, which
# is why pki/ldap.pem runs to 2030 (vlab/pki.py says so too).
#
# Recorded with OpenSSL 3.0.13, OpenSSH 9.6, OpenLDAP 2.6.7, curl 8.5,
# pyftpdlib 2.2 and Python 3.13,
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


grep -q 'ldap.vereda.example' /etc/hosts || echo '127.0.0.1 files.vereda.example ldap.vereda.example' >> /etc/hosts
id ana >/dev/null 2>&1 || { useradd -m -s /bin/bash ana; usermod -p '*' ana; }
install -d -m 700 -o ana /home/ana/.ssh; install -m 600 -o ana keys/ana_ssh.pub /home/ana/.ssh/authorized_keys
mkdir -p /run/sshd "$HOME/srv/ldap"; : > "$HOME/servers.pid"
for p in "$HOME/srv/sshd.pid" "$HOME/srv/ldap/slapd.pid"; do [ -f "$p" ] && kill "$(cat "$p")" 2>/dev/null; done; sleep 1
cat > "$HOME/srv/sshd_config" <<CONF
Port 2222
ListenAddress 127.0.0.1
HostKey $HOME/lab/keys/sftp_host_ed25519
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
StrictModes no
Subsystem sftp internal-sftp
PidFile $HOME/srv/sshd.pid
CONF
/usr/sbin/sshd -f "$HOME/srv/sshd_config"
setsid python3 -c "
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
a = DummyAuthorizer(); a.add_user('scheduler', 'V-db-s3cret-2026', '$HOME/lab/data/release', perm='elr')
FTPHandler.authorizer = a; FTPHandler.passive_ports = range(30000, 30001)
FTPServer(('127.0.0.1', 2121), FTPHandler).serve_forever()" </dev/null >/dev/null 2>&1 & echo $! >> "$HOME/servers.pid"
rm -rf "$HOME/srv/ldap/db"; mkdir -p "$HOME/srv/ldap/db"
cat > "$HOME/srv/ldap/slapd.conf" <<CONF
include /etc/ldap/schema/core.schema
pidfile $HOME/srv/ldap/slapd.pid
modulepath /usr/lib/ldap
moduleload back_mdb
TLSCertificateFile $HOME/lab/pki/ldap-chain.pem
TLSCertificateKeyFile $HOME/lab/pki/ldap.key
database mdb
suffix "dc=vereda,dc=example"
rootdn "cn=admin,dc=vereda,dc=example"
rootpw directory-admin-lab
directory $HOME/srv/ldap/db
security simple_bind=128
CONF
slapd -f "$HOME/srv/ldap/slapd.conf" -h "ldap://127.0.0.1:3389/ ldaps://127.0.0.1:6636/"
sleep 1
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

sleep 1; kill $(cat "$HOME/servers.pid" "$HOME/srv/sshd.pid" "$HOME/srv/ldap/slapd.pid") 2>/dev/null
