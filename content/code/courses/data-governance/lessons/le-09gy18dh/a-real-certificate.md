---
title: A certificate worth checking
version: 1
---

The lab has a certificate authority of its own, made by `lab.sh` with OpenSSL: a root,
**Ipe Lab Root CA**, and a certificate it signed for the database's name. In a company this is
the internal CA the platform team runs, or a public one when the database is reached from
outside. Before installing anything, read what it says:

```
ana@lab:~/gov$ openssl x509 -in /etc/ipe-pki/db.crt -noout -subject -issuer -ext subjectAltName
subject=O = Farmacia Ipe, CN = db.ipe.example
issuer=O = Farmacia Ipe, CN = Ipe Lab Root CA
X509v3 Subject Alternative Name: 
    DNS:db.ipe.example
ana@lab:~/gov$ openssl verify -CAfile /etc/ipe-pki/ca.crt /etc/ipe-pki/db.crt
/etc/ipe-pki/db.crt: OK
```

Three facts, each one a check the client will make:

- **the subject and the Subject Alternative Name say `db.ipe.example`** — the name clients
  connect to. Modern clients compare the host name against the SAN, not against the subject;
- **the issuer is the lab's root**, so a client that trusts the root trusts this;
- **`openssl verify` says OK**: the signature on it really was made by that root.

## Installing it on the server

```sql
-- The server's own certificate, signed by the lab CA, instead of the one
-- Ubuntu generated on the day the cluster was made.
ALTER SYSTEM SET ssl_cert_file = '/etc/postgresql/16/gov/db.crt';
ALTER SYSTEM SET ssl_key_file  = '/etc/postgresql/16/gov/db.key';
ALTER SYSTEM SET ssl_ca_file   = '/etc/postgresql/16/gov/ca.crt';
ALTER SYSTEM SET ssl_min_protocol_version = 'TLSv1.3';
SELECT pg_reload_conf();
```

```
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 644 /etc/ipe-pki/db.crt /etc/ipe-pki/ca.crt /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 600 /etc/ipe-pki/db.key /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo -u postgres psql < tls.sql
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)
```

The private key is the one file that matters, and it goes in with mode `600`, owned by
`postgres`: the server refuses to start with a key that other users can read, for the same reason
libpq refused Ana's password file in lesson 1. `ssl_min_protocol_version` refuses anything older
than TLS 1.3. Every client in the lab speaks it; a company with old clients would set 1.2 and
write down which clients are the reason.

## Giving the client the authority

```
ana@lab:~/gov$ mkdir -p ~/.postgresql && cp /etc/ipe-pki/ca.crt ~/.postgresql/root.crt
ana@lab:~/gov$ psql "service=bruno sslmode=verify-full" -c "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 ssl | version 
-----+---------
 t   | TLSv1.3
(1 row)
```

`verify-full` now works. The client checked that the certificate was signed by the root in
`root.crt` and that it was issued for `db.ipe.example`, the name in Bruno's service entry.

So every entry in Ana's service file gets the same line, and from here on every connection in
this course checks the server it talks to:

```
ana@lab:~/gov$ sed -i '/^user=/a sslmode=verify-full' ~/.pg_service.conf && grep -c verify-full ~/.pg_service.conf
3
ana@lab:~/gov$ psql service=carla -c "SELECT current_user, ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 current_user | ssl 
--------------+-----
 carla        | t
(1 row)
```

## The check that catches the wrong name

The second half of `verify-full` is the one people turn off when it gets in the way. The same
server, reached by its address instead of its name:

```
ana@lab:~/gov$ psql "host=127.0.0.1 port=5433 dbname=ipe user=bruno sslmode=verify-full" -c "SELECT 1"
psql: error: connection to server at "127.0.0.1", port 5433 failed: server certificate for "db.ipe.example" (and 1 other name) does not match host name "127.0.0.1"
```

The certificate is valid, signed by the trusted root, and **refused**, because it was issued for
`db.ipe.example` and the client asked for `127.0.0.1`. That refusal is the protection: a
certificate stolen from one host, or legitimately issued for a different one, does not work for
this one. The usual "fix" — dropping to `verify-ca` or `require` because the name does not match
— removes exactly the check that stops somebody presenting a certificate for another machine.
The right fix is to connect by the name the certificate carries, or to issue one that carries
the name you use.
