---
title: Protocols that send the password as typed
version: 1
---

**FTP, Telnet, HTTP, POP3, IMAP, SMTP and LDAP were all designed to send everything, credentials
included, as readable text.** They predate the public internet's threats, and each has been given an
encrypted version since. The old ones are still found running, usually because something depends on
them and nobody has switched them off.

## Three servers on your machine

This lesson talks to an FTP server, an SSH server and an LDAP directory, which is why it is the
first that needs more packages and the first that needs `sudo`. Ubuntu's packages give the three
programs; the installer of `slapd` asks for an administrator password for a directory this lesson
does not use, and any answer will do:

```sh
sudo apt-get install -y openssh-server slapd ldap-utils python3-pyftpdlib curl
```

One script starts all three, each on its own port of `127.0.0.1`, with lesson 8's certificates and
lesson 6's key for Ana. It runs as root because it starts `sshd`, creates a user `ana` for the SSH
server to accept, if your machine has none, and adds two names to `/etc/hosts`. In a virtual machine
that is the whole reason to prefer one:

```sh
#!/usr/bin/env bash
# ~/lab/bin/protocol-servers
# sudo protocol-servers start | stop: lesson 12's servers, on 127.0.0.1 only.
#
#   2121  FTP (pyftpdlib), account scheduler, serving ~/lab/data/release
#   2222  OpenSSH's sshd, SFTP only, a user ana who signs in with keys/ana_ssh
#   3389  OpenLDAP's slapd, plain LDAP with StartTLS, refusing a password sent
#         before TLS (security simple_bind=128)
#   6636  the same slapd over LDAPS, with lesson 8's pki/ldap-chain.pem
#
# It needs root: it starts sshd, adds the user ana if there is none, and adds
# files.vereda.example and ldap.vereda.example to /etc/hosts.
set -euo pipefail
lab=$(cd "$(dirname "$0")/.." && pwd)
run=/run/vereda-lab   # not in ~/lab: root writes here

stop() {
  for pid in "$run"/*.pid; do
    [ -f "$pid" ] && kill "$(cat "$pid")" 2>/dev/null
    rm -f "$pid"
  done
  return 0
}

start() {
  stop
  mkdir -p "$run/ldap" /run/sshd
  grep -q ldap.vereda.example /etc/hosts ||
    echo '127.0.0.1 files.vereda.example ldap.vereda.example' >> /etc/hosts

  # ana, with no password: the only way in is her key.
  id ana >/dev/null 2>&1 || { useradd -m -s /bin/bash ana; usermod -p '*' ana; }
  install -d -m 700 -o ana /home/ana/.ssh
  touch /home/ana/.ssh/authorized_keys
  grep -qF "$(cat "$lab/keys/ana_ssh.pub")" /home/ana/.ssh/authorized_keys ||
    cat "$lab/keys/ana_ssh.pub" >> /home/ana/.ssh/authorized_keys
  chown ana /home/ana/.ssh/authorized_keys

  cat > "$run/sshd_config" <<EOF
Port 2222
ListenAddress 127.0.0.1
HostKey $lab/keys/sftp_host_ed25519
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
StrictModes no
Subsystem sftp internal-sftp
PidFile $run/sshd.pid
EOF
  /usr/sbin/sshd -f "$run/sshd_config"

  setsid python3 -c "
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
a = DummyAuthorizer()
a.add_user('scheduler', 'V-db-s3cret-2026', '$lab/data/release', perm='elr')
FTPHandler.authorizer = a
FTPHandler.passive_ports = range(30000, 30001)
FTPServer(('127.0.0.1', 2121), FTPHandler).serve_forever()" </dev/null >/dev/null 2>&1 &
  echo $! > "$run/ftp.pid"

  rm -rf "$run/ldap/db"; mkdir -p "$run/ldap/db"
  cat > "$run/ldap/slapd.conf" <<EOF
include /etc/ldap/schema/core.schema
pidfile $run/slapd.pid
modulepath /usr/lib/ldap
moduleload back_mdb
TLSCertificateFile $lab/pki/ldap-chain.pem
TLSCertificateKeyFile $lab/pki/ldap.key
database mdb
suffix "dc=vereda,dc=example"
rootdn "cn=admin,dc=vereda,dc=example"
rootpw directory-admin-lab
directory $run/ldap/db
security simple_bind=128
EOF
  slapd -f "$run/ldap/slapd.conf" -h "ldap://127.0.0.1:3389/ ldaps://127.0.0.1:6636/"
  sleep 1
  echo "FTP on 2121, SFTP on 2222, LDAP on 3389 and LDAPS on 6636, all on 127.0.0.1"
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  *) echo "usage: sudo protocol-servers start | stop" >&2; exit 2 ;;
esac
```

The SSH server needs a key of its own, which `vcrypt sshkey` from lesson 6 writes from a label like
every other key. Then the servers start:

```sh
cd ~/lab
vcrypt sshkey keys/sftp-host keys/sftp_host_ed25519
chmod +x bin/protocol-servers
sudo ~/lab/bin/protocol-servers start
```

They run until the machine restarts or you type `sudo ~/lab/bin/protocol-servers stop`. `start`
stops whatever an earlier `start` left running before it begins, so typing it again is also how to
restart them.

## FTP, as the server receives it

Vereda's file server still offers FTP on port 2121 for an old scheduling tool. `curl -v` prints the
commands it sends, which are exactly the bytes that cross the network:

```
ana@lab:~/lab$ curl -sv --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (USER|PASS|RETR|230)|^Vereda'
> USER scheduler
> PASS V-db-s3cret-2026
< 230 Login successful.
> RETR NOTES.txt
Vereda portal 2.4.1: booking reminders by SMS.
```

`USER` and `PASS` carry the account name and the password as typed, and the file follows in clear
text too. Anybody on the path, a compromised switch, a shared Wi-Fi network, a misconfigured mirror
port, reads both without breaking anything. There is no cryptography to defeat.

## Asking for encryption the server cannot give

A client can insist on encryption. With `--ssl-reqd`, curl first asks the server to switch to TLS,
which is how **FTPS** works, and refuses to go on when the server cannot:

```
ana@lab:~/lab$ curl -sv --ssl-reqd --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (AUTH|USER|PASS|5)|^curl:'; echo "exit status ${PIPESTATUS[0]}"
> AUTH SSL
< 500 Command "AUTH" not understood.
> AUTH TLS
< 500 Command "AUTH" not understood.
exit status 64
```

The server answers `500` to both `AUTH SSL` and `AUTH TLS`, so curl stops with exit status 64
**before** sending `USER` or `PASS`. That ordering is the whole point of `--ssl-reqd`: a client that
only *prefers* encryption would have fallen back to plain FTP and sent the password anyway, which is
the downgrade problem of section 04.

## The pairs to know

| plain protocol | port | encrypted replacement | port |
|---|---|---|---|
| FTP | 21 | **SFTP** (file transfer over SSH), or FTPS (FTP over TLS) | 22, or 990 / 21 |
| Telnet | 23 | **SSH** | 22 |
| HTTP | 80 | **HTTPS** | 443 |
| LDAP | 389 | **LDAPS**, or LDAP with StartTLS | 636, or 389 |
| SMTP submission | 25, 587 | SMTP with STARTTLS, or implicit TLS | 587, 465 |
| IMAP, POP3 | 143, 110 | IMAPS, POP3S | 993, 995 |

The insecure one should not merely be **available alongside** the secure one: it should be **off**,
or refuse to authenticate, as the LDAP server at the end of this lesson does. A server that offers
both leaves every client one misconfiguration away from the plain version.
