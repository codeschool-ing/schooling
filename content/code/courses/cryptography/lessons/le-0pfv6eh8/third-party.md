---
title: A third party that vouches for a key
version: 1
---

**A certificate is a statement, signed by somebody you already trust, that a public key belongs to a
name.** That is the whole of the idea. Public key infrastructure, PKI, is everything needed to make
those statements trustworthy at the scale of the internet: who may sign them, how they are checked,
and what happens when one turns out to be false.

## The problem certificates solve

Lessons 2, 3 and 7 each stopped at the same point. A public key says nothing about whose it is, and
the signed key exchange that defeats a man in the middle only works if Ana knows which public key is
really the server's. She cannot ask the server: an impostor answers "yes, this is my key" exactly as
the real server would. She needs somebody else, who is not on the path, to have checked in advance.

For SSH, lesson 6 answered this by hand: an `allowed_signers` file, or the fingerprint a person
compares on first connection. That works for a team of ten. It does not work for a patient opening
Vereda's portal on a phone, who has never heard of a fingerprint and will never call anybody to
check one.

## What a certificate binds

Vereda's portal certificate names its subject, and the authority that issued it:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -subject -issuer
subject=C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
```

And it carries a public key:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhJUPnGMjGZ+5QuxX+6XKfF1Nrfun
GJflFVDf4FVcfDEtMAY90zJYuJG9Ryt/UVgdqhUMOiN5NyKvI2D3RuAJKQ==
-----END PUBLIC KEY-----
```

That key is the public half of the private key the portal server holds, byte for byte:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey | cmp - <(openssl pkey -in pki/portal.key -pubout) && echo "the certificate carries the public half of portal.key"
the certificate carries the public half of portal.key
```

So the certificate binds three things together: a **name** (`portal.vereda.example`), a **public
key**, and an **issuer** who signed the pair. A browser that trusts the issuer, and checks the
issuer's signature, can believe that this key belongs to that name. It still checks one thing more:
during the handshake, the server proves it holds the matching private key by signing the exchange
(lesson 7). A certificate on its own is public; anybody can copy it. Holding the private key is what
the handshake tests.

## What the authority actually checks

A **certificate authority** (CA) signs only after checking that the requester controls the name. For
the certificates browsers use, that check is usually automatic and about the domain alone:

- **domain validation (DV)**: the requester proves control of the domain, by serving a file at a
  given address or publishing a DNS record. Let's Encrypt automates this with the ACME protocol, and
  it is most of the web's certificates;
- **organisation validation (OV)** and **extended validation (EV)** add checks on the company behind
  the domain. Browsers stopped showing EV differently around 2019, because users did not notice the
  difference.

A DV certificate therefore says "whoever asked for this controlled `portal.vereda.example` at the
time", not "this is a trustworthy clinic". That is exactly what the browser needs to know to rule out
a man in the middle, and nothing more.
