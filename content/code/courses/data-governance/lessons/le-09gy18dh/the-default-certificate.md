---
title: The certificate nobody checks
version: 1
---

Lesson 1 ended with a line in the server's log: Carla's session was `SSL enabled`, protocol TLS
1.3, and nobody had configured anything. This is where that came from:

```
ana@lab:~/gov$ sudo -u postgres psql -c "SHOW ssl" -c "SHOW ssl_cert_file"
 ssl 
-----
 on
(1 row)

            ssl_cert_file             
--------------------------------------
 /etc/ssl/certs/ssl-cert-snakeoil.pem
(1 row)

ana@lab:~/gov$ sudo openssl x509 -in /etc/ssl/certs/ssl-cert-snakeoil.pem -noout -subject -issuer
subject=CN = localhost
issuer=CN = localhost
```

Ubuntu turns `ssl` on for every cluster it creates and points it at a certificate called
**snakeoil**, generated when the package was installed. Its subject is `localhost`, and its
issuer is `localhost` too: **it is self-signed**, vouched for by nobody but itself. The name is
honest about it: snake oil is the remedy that cures nothing.

And yet the connection *is* encrypted:

```
ana@lab:~/gov$ psql service=bruno -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
 ssl | version |         cipher         
-----+---------+------------------------
 t   | TLSv1.3 | TLS_AES_256_GCM_SHA384
(1 row)
```

`pg_stat_ssl` is the server's view of every session's encryption, and this one reads TLS 1.3 with
AES-256 in GCM mode — a strong cipher, correctly negotiated. Somebody listening on the network
between Bruno and the server sees ciphertext.

## What the certificate was supposed to add

**Encryption keeps a listener out. It does not tell you who you are talking to.** A certificate
is what answers that: a signature from somebody the client trusts, saying that the key on the
other end belongs to `db.ipe.example`. Without a check, the client would encrypt just as happily
to a machine that put itself in the middle of the path and presented a key of its own — and the
password exchange, the queries and the rows would all be encrypted, to the wrong party.

SCRAM, from lesson 1, makes that harder than it sounds, because the password never crosses the
wire. But the queries and the results do, and a pipeline that pulls every customer each night is
worth intercepting for its results alone. So a connection carrying personal data should check
the certificate, which means somebody has to issue one worth checking.

## A check is only as good as what it is checked against

The snakeoil certificate cannot be checked usefully, because there is nothing to check it
against: every Ubuntu machine has its own, all called `localhost`, each signed by itself. Section
5 replaces it with one issued by the lab's certificate authority, for the name clients actually
use. First, the client side: what psql does today, and why it never complained.
