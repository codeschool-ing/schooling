---
title: What each half costs
version: 1
---

The reason protocols do not use asymmetric cryptography for everything is measurable. `openssl speed`
runs each operation for a second on `laptop` and reports how many it managed. Symmetric first, AES-256
in GCM mode on 16 KiB blocks:

```
ana@laptop:~$ openssl speed -seconds 1 -bytes 16384 -evp aes-256-gcm 2>/dev/null | tail -2
type          16384 bytes
AES-256-GCM   12552994.82k
```

**12,552,994.82 thousand bytes a second**, about 12.5 gigabytes, on one processor core with the AES
instructions modern processors carry. Then RSA with a 2048-bit key, and X25519:

```
ana@laptop:~$ openssl speed -seconds 1 rsa2048 2>/dev/null | tail -2
                  sign    verify    sign/s verify/s
rsa 2048 bits 0.000302s 0.000017s   3313.0  57718.2
ana@laptop:~$ openssl speed -seconds 1 ecdhx25519 2>/dev/null | tail -2
                              op      op/s
 253 bits ecdh (X25519)   0.0000s  29568.7
```

**3,313 RSA signatures a second** against 57,718 verifications, and **29,568.7 X25519 key agreements**.
Put side by side:

| operation | per second on `laptop` | what it is used for |
|---|---|---|
| AES-256-GCM, 16 KiB blocks | about 766,000 blocks (12.5 GB) | every byte of a connection |
| X25519 key agreement | 29,568.7 | once per connection, to agree the key |
| RSA-2048 signature | 3,313 | once per connection, by the server, to prove its identity |

Encrypting a 16 KiB block is some twenty-five times faster than one X25519 agreement, and there are
thousands of blocks in a connection against one agreement. **That is the design of every secure
protocol in one table**: the slow operations run once, at the start, and the fast one carries the data.

The numbers belong to this machine on this afternoon; run `openssl speed` on another and they change.
The ratios are what travel. They are also why a busy TLS server feels its RSA signatures first, and why
the move to elliptic-curve keys, far cheaper to sign with, was welcomed by the people paying for the
servers.
