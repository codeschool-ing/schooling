---
title: Reading a cipher suite
version: 1
---

The two answers in the previous section named what each connection used. A TLS 1.2 **cipher suite**
names four choices at once, and every piece maps onto a lesson of this course:

| piece of `ECDHE-ECDSA-AES256-GCM-SHA384` | what it chooses | lesson |
|---|---|---|
| `ECDHE` | key agreement: elliptic-curve Diffie-Hellman, **ephemeral**, fresh per connection | 10 |
| `ECDSA` | how the server proves it holds its certificate's key: an ECDSA signature | 11, 12 |
| `AES256-GCM` | the symmetric cipher for the data, authenticated | 10 |
| `SHA384` | the hash used inside the handshake to derive keys | 11 |

TLS 1.3 simplified the name to the part that varies, `TLS_AES_256_GCM_SHA384`: the key agreement is
always ephemeral Diffie-Hellman and the signature is fixed by the certificate, so neither is left to
negotiate. **That removed whole categories of weak choice at once**: TLS 1.3 has no suite without
forward secrecy and no cipher without authentication.

What to require on a server, stated as properties rather than a list that will age:

- **ephemeral key agreement** (`ECDHE` or `DHE`): forward secrecy, so a key stolen next year does not
  unlock this year's recordings;
- **authenticated encryption** (`GCM` or `CHACHA20-POLY1305`): lesson 10's refusal of a changed byte;
- **no** RSA key exchange, CBC-mode suites, RC4, 3DES or anything labelled `EXPORT` or `NULL`.

A server offering only TLS 1.2 and 1.3 with those properties, like this one, needs no further cipher
configuration for most purposes; the defaults of current software are the list above.
