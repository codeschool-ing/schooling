---
title: After the quantum computer: ML-KEM and hybrid exchanges
version: 1
---

**A large enough quantum computer, running Shor's algorithm, would solve both the factoring problem
behind RSA and the discrete logarithm behind Diffie-Hellman and elliptic curves.** Every key
exchange in this lesson would fall. Such a machine does not exist yet, and nobody can say when it
will. The response is already being deployed anyway, because of one property of recorded traffic.

## Why it matters before the machine exists

Section 04 showed that recorded traffic stays readable for whoever later obtains the key. A quantum
computer is a way of obtaining it. Traffic recorded today and protected by X25519 alone could be
decrypted on the day such a machine runs. This is called **"harvest now, decrypt later"**, and it
means the deadline for data that must stay secret for twenty years, such as medical records, is
already here. Signatures are less urgent: a forged signature needs the machine at the moment of
forging, so there is time to replace them before it exists.

## ML-KEM, the replacement for the exchange

In August 2024 NIST published its first three post-quantum standards: **FIPS 203 (ML-KEM)** for
establishing keys, and **FIPS 204 (ML-DSA)** and **FIPS 205 (SLH-DSA)** for signatures. ML-KEM, from
the Kyber design, rests on a problem about lattices that no known quantum algorithm solves
efficiently.

It is a **key encapsulation mechanism** rather than an exchange: one side publishes a public key, the
other uses it to produce a shared secret and a ciphertext that carries it, and the first side
recovers the secret with its private key. The effect is the same, both sides end with a 32-byte
secret, and so is the size of that secret. Python's `cryptography` has ML-KEM-768 in the version the
lab pinned, and `vcrypt kem` makes a key pair, encapsulates once, and prints the sizes:

```py
# ~/lab/tools/kem.py
"""vcrypt kem: an ML-KEM-768 key pair, one encapsulation, and the sizes.
Encapsulation is randomised, so the secret itself is never printed."""
from cryptography.hazmat.primitives.asymmetric import mlkem

import drbg

k = mlkem.MLKEM768PrivateKey.from_seed_bytes(drbg.stream("keys/mlkem768", 64))
pub = k.public_key()
secret, ciphertext = pub.encapsulate()
print(f"ML-KEM-768 public key      {len(pub.public_bytes_raw()):5} bytes")
print(f"encapsulation (ciphertext) {len(ciphertext):5} bytes")
print(f"shared secret              {len(secret):5} bytes")
print(f"decapsulated secret matches: {'yes' if k.decapsulate(ciphertext) == secret else 'no'}")
```

Everything else is bigger:

```
ana@lab:~/lab$ vcrypt kem
ML-KEM-768 public key       1184 bytes
encapsulation (ciphertext)  1088 bytes
shared secret                 32 bytes
decapsulated secret matches: yes
```

Compare X25519's public key, the whole of it:

```
ana@lab:~/lab$ openssl pkey -pubin -in keys/x25519-ana.pub -noout -text
X25519 Public-Key:
pub:
    49:36:f3:2c:15:64:30:b6:58:5f:07:9e:a2:fd:8f:
    7d:81:2d:4f:9a:1f:15:a4:4d:18:2c:1b:4c:3d:00:
    69:12
```

32 bytes against 1,184 for the public key, and 1,088 for what the other side sends back. Bigger
messages are the main practical cost of the transition.

## Hybrid, because nobody bets on one problem

ML-KEM is new, and new algorithms have surprised people: SIKE, one of NIST's candidates, was broken
in 2022 on an ordinary computer. So the deployed answer is **hybrid**: run X25519 and ML-KEM-768
together and derive the session keys from both secrets. An attacker has to break both, one with a
quantum computer and the other with mathematics nobody has. In TLS 1.3 this is the group
**X25519MLKEM768**, enabled by default in current Chrome, Firefox and Cloudflare, and supported by
OpenSSL from version 3.5. The OpenSSL in this lab, 3.0, predates it, which is why the capture uses
the Python library's ML-KEM.

## What to do about it now

- **Inventory** where key exchange happens and which library does it, the same lesson as MD5 and
  SHA-1 in lesson 4. Migration is a library upgrade in most places and a hardware replacement in
  some.
- Prefer the **hybrid** group where your TLS stack offers it, starting with anything that carries
  data with a long life.
- **Symmetric cryptography survives.** Grover's algorithm only halves the effective length of a key,
  so AES-256 keeps 128 bits of strength, and SHA-256 keeps its uses. Nothing in lessons 1, 4 or 5
  needs replacing for this.
- NIST's transition plan proposes to deprecate RSA and elliptic-curve algorithms by 2030 and to
  disallow them by 2035. Anything built now will still be running then.
