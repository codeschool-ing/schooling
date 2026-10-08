---
title: sslmode, or what the client is willing to accept
version: 1
---

Whether a connection is encrypted, and whether the client checks who answered, is decided by the
**client**, in one setting: `sslmode`. The server can insist on TLS (section 6 does), but only
the client can insist on checking the certificate.

Bruno's service entry says nothing about it, so psql uses the default, `prefer`. Asking for
nothing is allowed too:

```
ana@lab:~/gov$ psql "service=bruno sslmode=disable" -c "SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 ssl 
-----
 f
(1 row)
```

**The server accepted a plaintext connection**, because nothing in `pg_hba.conf` refuses one: a
`host` line matches both. That is the first gap. The second is in the default itself:

| sslmode | encrypts | checks the certificate | if TLS is not available |
|---|---|---|---|
| `disable` | no | — | plaintext |
| `allow` | only if the server insists | no | plaintext |
| `prefer` (the default) | if the server offers it | no | **plaintext, silently** |
| `require` | yes | no | refuses |
| `verify-ca` | yes | that a trusted CA signed it | refuses |
| `verify-full` | yes | that a trusted CA signed it **for this host name** | refuses |

**`prefer` is a word to read carefully.** It means: try TLS, and if that fails for any reason, try
again without it and say nothing. Lesson 1 saw it happen: every wrong password was refused twice,
once with encryption and once without, because the client fell back after the first refusal.
Somebody able to interfere with the connection can make the first attempt fail on purpose, and
`prefer` will hand them the second. `require` closes that and still trusts any certificate;
**`verify-full` is the only mode that is safe against somebody in the middle.**

Asking for it today fails, for a reason the client spells out:

```
ana@lab:~/gov$ psql "service=bruno sslmode=verify-full" -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: root certificate file "/home/ana/.postgresql/root.crt" does not exist
Either provide the file, use the system's trusted roots with sslrootcert=system, or change sslmode to disable server certificate verification.
```

`verify-full` needs to know which certificate authorities to trust, and by default looks for
them in `~/.postgresql/root.crt`. There is no such file, and even if there were, the snakeoil
certificate is signed by no authority to put in it. The fix has two halves: the server needs a
certificate signed by an authority, and the client needs that authority's certificate. The next
section does both.

The message also offers `sslrootcert=system`, available since PostgreSQL 16: trust the operating
system's own list of public authorities. That is right for a managed database in a cloud, whose
certificate is signed by a public CA. Ipê's lab uses a private one, so the client is given it
explicitly.
