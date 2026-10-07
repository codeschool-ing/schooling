---
title: Diffie-Hellman with numbers you can check
version: 1
---

**In a Diffie-Hellman exchange, two parties each keep a secret number, send each other a value
computed from it, and each arrive at the same shared secret, which never crosses the network.**
Nobody is sent a key. Nothing is encrypted to anybody. The secret is *agreed*, and an eavesdropper
who saw every message still cannot compute it. Whitfield Diffie and Martin Hellman published the
idea in 1976, and it is the first step of every TLS, SSH and WireGuard connection made today.

## The exchange, small enough to do by hand

`vcrypt toydh` runs the textbook example with a prime of 23:

```
ana@lab:~/lab$ vcrypt toydh
public:  p = 23, g = 5
Ana   picks a = 6 (secret), sends A = g^a mod p = 8
Bruno picks b = 15 (secret), sends B = g^b mod p = 19
Ana   computes B^a mod p = 2
Bruno computes A^b mod p = 2
on the wire: p, g, A = 8, B = 19; never a, b or the result
```

Step by step:

1. Both sides agree on two **public** numbers, the prime `p = 23` and a base `g = 5`. These can be
   published; in practice they are fixed by a standard.
2. Ana picks a secret `a = 6` and sends `A = 5⁶ mod 23 = 8`.
3. Bruno picks a secret `b = 15` and sends `B = 5¹⁵ mod 23 = 19`.
4. Ana raises what she received to her own secret: `19⁶ mod 23 = 2`.
5. Bruno does the same with his: `8¹⁵ mod 23 = 2`.

Both get 2, because both computed `5^(6×15) mod 23`, each from a different half. The last line of the
output is the point: what travelled was `23`, `5`, `8` and `19`. To get 2 from those, an
eavesdropper must recover 6 from `8 = 5^a mod 23`, which is the **discrete logarithm problem**. With
23 it takes a moment; with a prime of 2048 bits, or on an elliptic curve of 256 bits, it is the same
kind of problem lesson 2 said nobody can solve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Diffie-Hellman with p = 23 and g = 5. Ana keeps a = 6 and sends A = 8. Bruno keeps b = 15 and sends B = 19. The network carries only 23, 5, 8 and 19. Ana computes 19 to the 6 mod 23 and Bruno computes 8 to the 15 mod 23; both get 2.\"><defs><marker id=\"dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><text x=\"610\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Bruno</text><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">the network</text><rect x=\"260\" y=\"36\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">p = 23, g = 5</text><rect x=\"30\" y=\"40\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">secret a = 6</text><rect x=\"530\" y=\"40\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">secret b = 15</text><polyline points=\"190,100 530,100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dh-ah-phosphor)\"></polyline><text x=\"360\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">A = 5^6 mod 23 = 8</text><polyline points=\"530,140 190,140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dh-ah-phosphor)\"></polyline><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">B = 5^15 mod 23 = 19</text><rect x=\"30\" y=\"196\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">19^6 mod 23 = 2</text><rect x=\"530\" y=\"196\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8^15 mod 23 = 2</text><text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">same secret, never sent</text></svg>", "caption": "Two halves of one exponent; the network sees neither half."}
```

## What an exchange gives, and what it does not

The result is a **shared secret** that only the two participants know. It is not used as a key
directly. Both sides pass it through a key derivation function, in TLS 1.3 **HKDF**, to produce the
actual AES or ChaCha20 keys, one for each direction. The next section does that step with real keys.

Two things the exchange does not do, and each is a section of this lesson:

- it does not say **who** is on the other end. Ana knows she agreed a secret with *somebody* who
  sent 19. Section 05 is about why that matters and how protocols fix it;
- it does not survive a **large quantum computer**, which would solve the discrete logarithm
  efficiently. Section 06 is about what replaces it.
