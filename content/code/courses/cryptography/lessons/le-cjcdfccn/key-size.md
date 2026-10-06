---
title: How many bits is enough
version: 1
---

**Key sizes are compared by their security level: roughly, the number of operations an attacker
would need, written as a power of two.** A 128-bit security level means about 2¹²⁸ operations,
and that is the target for anything that has to stay secret for decades. The catch is that the
three families reach it with very different numbers of bits, so "256" on its own means nothing
until you know which family it belongs to.

## The table that answers the question

NIST's key management recommendation, SP 800-57, lines the families up by security level:

| security level | symmetric (AES) | elliptic curve | RSA modulus |
|---|---|---|---|
| 112 bits | (3DES, retired) | 224 | 2048 |
| **128 bits** | **AES-128** | **256 (P-256, X25519)** | **3072** |
| 192 bits | AES-192 | 384 (P-384) | 7680 |
| 256 bits | AES-256 | 512 (P-521) | 15360 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Bars showing the key length each family needs for a 128-bit security level: AES 128 bits, an elliptic curve 256 bits, RSA 3072 bits. The RSA bar is twelve times the curve&#x27;s and twenty-four times AES&#x27;s.\"><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">key length for 128-bit security</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES-128</text><rect x=\"120\" y=\"50\" width=\"23.333333333333332\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"151.33333333333334\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">128 bits</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">P-256</text><rect x=\"120\" y=\"106\" width=\"46.666666666666664\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"174.66666666666666\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">256 bits</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">RSA-3072</text><rect x=\"120\" y=\"162\" width=\"560.0\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"670.0\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3072 bits</text></svg>", "caption": "The same 128-bit security level, in three families."}
```

Three things follow from it, and each is a decision people get wrong:

- **AES-128, P-256 and RSA-3072 are equally strong.** Choosing RSA-4096 next to AES-128 buys
  nothing, because the attacker goes for the weaker one.
- **RSA grows badly.** Each step up costs RSA far more bits than it costs a curve, and RSA's work
  grows faster than its size: signing with a 15360-bit key is impractically slow, which is why
  nobody does it, and why curves won the higher levels.
- **RSA-2048 sits one level below the others**, at 112 bits. It is still acceptable today, and it
  is the floor: NIST's transition plan (IR 8547, a draft published in 2024) proposes to deprecate
  112-bit security after 2030. Anything issued now with a long life should be RSA-3072 or a
  curve.

## What size costs on the wire

Bigger keys travel in every handshake and every certificate. The lab's public keys, in the binary
form a certificate carries them:

```
ana@lab:~/lab$ for k in rsa-2048 rsa-3072 p256 ed25519-ana; do printf "%-12s %4s bytes\n" $k $(openssl pkey -pubin -in keys/$k.pub -outform DER | wc -c); done
rsa-2048      294 bytes
rsa-3072      422 bytes
p256           91 bytes
ed25519-ana    44 bytes
```

And signatures over the same letter, made with each private key:

```
ana@lab:~/lab$ for k in rsa-2048 rsa-3072; do openssl dgst -sha256 -sign keys/$k.key -out $k.sig data/referral.txt; done
ana@lab:~/lab$ openssl pkeyutl -sign -rawin -inkey keys/ed25519-ana.key -in data/referral.txt -out ed25519-ana.sig
ana@lab:~/lab$ wc -c rsa-2048.sig rsa-3072.sig ed25519-ana.sig
256 rsa-2048.sig
384 rsa-3072.sig
 64 ed25519-ana.sig
704 total
```

An RSA signature is exactly as long as the modulus: 256 bytes at 2048 bits, 384 at 3072. An
Ed25519 signature is 64 bytes whatever is signed. In a TLS handshake carrying a chain of two
certificates, each with a key and a signature, that difference is several hundred bytes per new
connection, which is one reason curves are the default for new certificates.

## What the size does not protect against

Every number in the table assumes the algorithm is used correctly and the key was generated from
good randomness. None of it helps when:

- **the key leaks.** A 15360-bit RSA key copied into a public repository protects nothing. Lesson
  17 is about this, and it is far more common than anybody factoring anything;
- **the random generator was weak.** In 2008 Debian's OpenSSL package could only produce 32,768
  different keys per type and size because of a patch to its random generator, so every SSH and TLS
  key made on those machines for two years had to be replaced, whatever its length;
- **a large quantum computer exists.** Shor's algorithm would break RSA and elliptic curves at
  every size in the table, while it only halves the effective strength of AES (AES-256 would still
  give 128 bits). That machine does not exist yet, but data recorded today could be decrypted on
  the day it does, and that is why lesson 7 ends with the post-quantum algorithms NIST standardised
  in 2024.

The working rule, then: **AES-256 or AES-128 for data, X25519 or P-256 for agreeing on keys,
Ed25519, P-256 or RSA-3072 for signatures, and RSA-2048 only where something old requires it.**
