---
title: A checksum anybody can recompute proves nothing
version: 1
---

**Integrity against accidents and integrity against an adversary are different properties.** A
checksum catches a cable that flipped a bit. It does not catch a person who changed the message,
because that person can recompute the checksum too. This lesson is about the second kind, and it
starts by showing why the first is not enough.

## A payment notice, and a hash beside it

Vereda's portal learns that a patient has paid through a message from its payment gateway, a small
piece of JSON:

```
ana@lab:~/lab$ cat data/webhooks/evt-1.json; echo
{"event":"payment.confirmed","booking":4471,"amount":12000}
```

Suppose the gateway sent its SHA-256 alongside, so that the portal can check nothing was changed:

```
ana@lab:~/lab$ sha256sum data/webhooks/evt-1.json
29907c15a04982fb68cfa1836a41d97f53f33fb3b0fdef9c3b67077e560729bd  data/webhooks/evt-1.json
```

Now somebody between the gateway and the portal changes the amount from 12000 cents to 120 and
recomputes the digest:

```
ana@lab:~/lab$ sed 's/12000/120/' data/webhooks/evt-1.json > forged.json; sha256sum forged.json
4f9653ccf5a9c5a2474a9bb3b437fdda1c8d7ef322d2dfada0a3938f0f4bcebf  forged.json
```

The portal receives a body and a digest that match each other perfectly. Lesson 4 said this in
general: **a hash has no key, so whoever can change the message can change the hash.** The digest
proves the body was not damaged after the digest was computed. It says nothing about who computed it.

## What the portal actually needs

Two properties, which come together in practice:

- **integrity against an adversary**: if anybody changed the message, the check fails;
- **authenticity of origin**: the check can only have been produced by the gateway.

Both need something the attacker does not have, which means a key. There are two ways to use one:

| | shared secret key | key pair |
|---|---|---|
| mechanism | **MAC**, in practice HMAC | **digital signature**, lesson 3 |
| who can produce the check | anybody holding the shared key | only the holder of the private key |
| who can verify it | anybody holding the shared key | anybody holding the public key |
| proves to a third party who sent it | no: either side could have made it | yes: non-repudiation |
| cost | microseconds | far slower, and needs a public key to be trusted |

The gateway and Vereda already share a secret, issued when Vereda opened its account, so the
gateway uses the left column. A software release, checked by thousands of people who share nothing
with its author, uses the right one. The next three sections take them in that order.
