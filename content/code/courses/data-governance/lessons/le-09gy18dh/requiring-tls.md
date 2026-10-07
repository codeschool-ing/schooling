---
title: Making the server insist
version: 1
---

`verify-full` protects a client that asks for it. A client that does not ask — an old script, a
BI tool with a checkbox nobody ticked, a colleague's laptop with the default `prefer` — can still
connect in plaintext, because the server allows it. The server's half is in `pg_hba.conf`, which
has two connection types lesson 1 did not use: **`hostssl`** matches only encrypted connections,
and **`hostnossl`** only unencrypted ones.

```conf
# TYPE     DATABASE  USER        ADDRESS        METHOD
local      all       postgres                   peer
local      ipe       ana                        peer
hostnossl  all       all         all            reject
hostssl    ipe       etl_loader  127.0.0.1/32   cert
hostssl    ipe       all         127.0.0.1/32   scram-sha-256
host       all       all         all            reject
```

Read from the top, as the server does:

- the socket lines are unchanged — a local socket never crosses a network;
- **any connection without TLS is refused**, by name, before anything else is considered;
- `etl_loader` over TLS logs in by **certificate** instead of password — the next section;
- everybody else over TLS uses SCRAM, as before;
- the last line refuses whatever is left.

```
ana@lab:~/gov$ sudo install -o postgres -g postgres -m 640 pg_hba.conf /etc/postgresql/16/gov/
ana@lab:~/gov$ sudo -u postgres psql -c "SELECT pg_reload_conf()" >/dev/null
ana@lab:~/gov$ psql "service=bruno sslmode=disable" -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  pg_hba.conf rejects connection for host "127.0.0.1", user "bruno", database "ipe", no encryption
```

The plaintext connection that worked in section 4 is refused, and the log will say `no
encryption` beside it. **That line in `pg_hba.conf` is what makes encryption in transit a policy
rather than a habit**: it no longer depends on every client being configured well.

## What it does not do

It insists on encryption; it cannot insist that the client *checked* the server's certificate.
A client with `sslmode=require` connects over TLS, satisfies `hostssl`, and still trusts whatever
certificate it was shown. Verifying the server stays the client's job, and the place to make it
the default is wherever clients are configured: a service file, a connection string in a secret
store, the settings of a BI tool. A review of a data platform asks to see those, not only the
server.

The server can, however, insist on a certificate **from the client**, and for a program that
connects every night with nobody watching, that is the stronger choice.
