---
title: Elliptic curves, the same idea with smaller keys
version: 1
---

**Elliptic-curve cryptography replaces RSA's factoring problem with another one-way problem, and it
needs keys about a tenth of the size for the same strength.** A 256-bit curve key matches a
3072-bit RSA key. That is why new protocols, phones and smart cards use curves, and why the lab's
server certificate in lesson 8 carries one.

## A number and a point

An elliptic curve, for cryptography, is a set of points defined by an equation over a finite field,
and those points can be "added" to each other by a fixed rule. One point of the curve, called the
**generator** `G`, is fixed by the standard. Then:

- the **private key** is a number `k`, picked at random below the number of points;
- the **public key** is the point `k × G`, which is `G` added to itself `k` times by a shortcut
  that takes a few hundred steps even when `k` has 77 digits.

Going forward, from `k` to `k × G`, is fast. Going back, from the point to `k`, is the **elliptic
curve discrete logarithm problem**, and for a well-chosen curve the best known methods take about
2¹²⁸ steps at 256 bits. The lab's P-256 key shows both halves:

```
ana@lab:~/lab$ openssl pkey -in keys/p256.key -noout -text
Private-Key: (256 bit)
priv:
    cc:ed:82:e0:7b:de:b0:17:25:72:95:27:2b:a8:9e:
    aa:1d:a1:e0:a3:ec:e1:f7:86:c5:9a:66:fb:90:62:
    99:c8
pub:
    04:ec:ad:7f:5a:17:42:6d:02:3c:45:bc:46:05:a7:
    30:88:6d:9d:eb:05:20:40:71:a5:45:6d:d8:a2:16:
    b0:be:4f:e3:80:7c:1e:0e:d8:4e:bc:7a:53:a9:72:
    df:4e:7f:a9:9c:50:10:7b:e6:df:3b:51:47:d9:50:
    29:73:24:41:dd
ASN1 OID: prime256v1
NIST CURVE: P-256
```

`priv` is the number `k`: 32 bytes, 256 bits. `pub` is the point: the leading `04` says it is
written *uncompressed*, followed by its two coordinates, 32 bytes of x and 32 bytes of y, 65 bytes
in all. The last two lines name the curve, and that is the decision a defender actually makes.

## Choose a named curve, never a custom one

Nobody using curves picks their own equation. A small set of **named curves** has been examined
for years, and choosing one of them is the whole decision:

| curve | where it is used | notes |
|---|---|---|
| **P-256** (`prime256v1`, `secp256r1`) | TLS certificates, smart cards, most enterprise systems | NIST standard; the most widely deployed |
| **X25519** | key exchange in TLS 1.3, SSH, Signal, WireGuard | designed to be hard to implement wrongly |
| **Ed25519** | signatures in SSH keys, package signing, the lab's `ed25519-*` keys | deterministic signatures, below |
| **secp256k1** | Bitcoin and Ethereum | outside those, rarely a reason to pick it |

X25519 and Ed25519 are the same underlying curve, Curve25519, used for two different jobs: X25519
agrees on a key (lesson 7), Ed25519 signs (lessons 3 and 6). They are not interchangeable, and a
library will refuse to use one key for the other.

## The failure that belongs to curves

RSA's typical failure was missing padding. ECDSA, the signature algorithm used with P-256, has its
own, and it has caused real disasters: **every ECDSA signature needs a fresh secret random number,
and a repeated or predictable one reveals the private key** to anybody holding two signatures.
Sony's PlayStation 3 signing key was recovered in 2010 because the same number was used for every
signature, and Android wallets lost bitcoins in 2013 because a broken random number generator gave
repeats.

The defence is to remove the randomness from the signer's hands. **Ed25519 derives that number
deterministically** from the private key and the message, so the same message always gives the
same signature and no generator can betray it. RFC 6979 does the same for ECDSA, and modern
libraries use it. If you are choosing a signature algorithm for something new, Ed25519 is the
default with the fewest ways to go wrong.

## What curves do not change

Curves change the size of the keys and the speed, not the shape of what this course teaches. There
is still a public half and a private half, the public half still says nothing about who owns it,
and the private half still must never leave its owner. They also share RSA's weakness against a
large quantum computer, which is the subject of the last section of lesson 7.
