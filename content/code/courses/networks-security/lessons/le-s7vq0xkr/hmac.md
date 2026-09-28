---
title: A keyed hash between two systems that share a secret
version: 1
---

A hash has no key, so anybody can compute it. Add a key and only the holders of the key can: that is
an **HMAC**, a hash-based message authentication code. It proves a message came from somebody who knows
the secret and was not changed on the way.

The everyday use is a **webhook**. A payment provider tells the shop that order 17 was paid by sending
a request to the shop's server, and signs the body with a secret the two agreed when the integration
was set up. The shop computes the same HMAC over the body it received, with its copy of the secret,
and compares:

```
ana@laptop:~$ printf "order=17&status=paid" | openssl dgst -sha256 -hmac "shared-webhook-secret"
SHA2-256(stdin)= 263351323f062f7dcf2f5eefc9c7429d1833ab81eebebb33976d309d94db5d0b
```

With the wrong secret, the value has nothing in common with the right one:

```
ana@laptop:~$ printf "order=17&status=paid" | openssl dgst -sha256 -hmac "a-guessed-secret"
SHA2-256(stdin)= 05fcb886ae5dfd8a2a1a069e989254211bcde9a86da7509b3b579b58f20f6361
```

So a request to the shop's webhook claiming `status=paid` is believed **only if its HMAC matches**.
Without that check, anybody who finds the webhook's address can mark orders as paid, because the
request needs no password and the address is not a secret.

Two details decide whether an HMAC check is sound:

- **compare in constant time.** A comparison that stops at the first differing byte answers faster
  for a guess that shares a longer prefix, and that timing leaks the value byte by byte. Libraries
  offer a comparison that always takes the same time, such as `hmac.compare_digest` in Python.
- **include what must not be replayed.** An HMAC over the body alone lets somebody resend yesterday's
  genuine request. Providers add a timestamp to what is signed and reject old ones.

HMAC has the limitation of every shared secret: **both sides can create valid codes**, so it proves the
message came from one of the two, not which. When a third party has to be able to check who signed,
the tool is a signature.
