---
title: The mode decides what the blocks give away
version: 1
---

AES encrypts one block. A **mode of operation** decides how a file of many blocks is encrypted
with it, and the choice matters more than the key size: **with the wrong mode, a ciphertext shows
the structure of the plaintext to somebody who has no key at all.**

## ECB: every block on its own

The obvious mode is to encrypt each block separately with the same key. It is called ECB,
*electronic codebook*, because it works like a codebook: a given block always becomes the same
ciphertext block. `vcrypt blocks --letters` draws one letter per block, the same letter for the
same block, four slots to the hour. First the plaintext, then the same file encrypted with ECB:

```
ana@lab:~/lab$ vcrypt blocks --letters data/slots.dat
ABAA BABA BAAA BAAA AABB AAAA BAAA BABA
ana@lab:~/lab$ openssl enc -aes-256-ecb -K $(cat keys/aes-256.hex) -in data/slots.dat | vcrypt blocks --letters -
ABAA BABA BAAA BAAA AABB AAAA BAAA BABA C
```

The two lines are the same. A was a free slot and B a booked one, so the ciphertext tells anybody
who holds it that Monday has bookings at 08:15, 09:00, 09:30, 10:00 and 11:00, two in a row from 13:30,
and three more from 15:00. Nobody broke AES to learn that. Each block is perfectly encrypted, and **the mode published
which blocks are equal**. (The extra C at the end is the block of padding from the previous
section.)

The well-known picture of this is a bitmap of a penguin encrypted with ECB, in which the penguin is
still perfectly visible. The appointment file is the same thing without the image: any repetition
in the data survives encryption.

## CBC: each block depends on the one before

CBC, *cipher block chaining*, removes the repetition by mixing each plaintext block with the
previous ciphertext block before encrypting it. The first block has no previous block, so it is
mixed with an **initialisation vector**, sixteen bytes that travel with the ciphertext:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two modes side by side. In ECB, three plaintext blocks P1, P2 and P3 each go through AES with key k on their own; P1 and P3 are the same, so C1 and C3 come out the same. In CBC, P1 is first combined by XOR with the IV, then each later block is combined with the previous ciphertext block before AES, so C1 and C3 differ although P1 equals P3.\"><defs><marker id=\"mode-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mode-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"mode-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ECB</text><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CBC</text><rect x=\"5\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P1 = free</text><polyline points=\"45,66 45,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"15\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"45,142 45,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"5\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C1 = 7f3a…</text><rect x=\"95\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P2 = BOOKED</text><polyline points=\"135,66 135,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"105\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"135,142 135,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"95\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C2 = 91c0…</text><rect x=\"185\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P3 = free</text><polyline points=\"225,66 225,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"195\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"225,142 225,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"185\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C3 = 7f3a…</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">C1 and C3 are equal: the pattern survives.</text><rect x=\"370\" y=\"74\" width=\"40\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">IV</text><rect x=\"405\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P1 = free</text><polyline points=\"445,66 445,78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><text x=\"445\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">XOR</text><polyline points=\"445,95 445,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"415\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"445,142 445,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"405\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C1 = 2b81…</text><polyline points=\"445,166 500,166 500,86 532,86\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-phosphor)\"></polyline><rect x=\"505\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P2 = BOOKED</text><polyline points=\"545,66 545,78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><text x=\"545\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">XOR</text><polyline points=\"545,95 545,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"515\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"545,142 545,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"505\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C2 = e04d…</text><polyline points=\"545,166 600,166 600,86 632,86\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-phosphor)\"></polyline><rect x=\"605\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P3 = free</text><polyline points=\"645,66 645,78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><text x=\"645\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">XOR</text><polyline points=\"645,95 645,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"615\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"645,142 645,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"605\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C3 = 5a17…</text><polyline points=\"410,86 437,86\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-amber)\"></polyline><text x=\"380\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Each block also depends on everything before it.</text><text x=\"380\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Hex values shortened and illustrative.</text></svg>", "caption": "ECB encrypts each block alone; CBC feeds each ciphertext block into the next."}
```

Equal plaintext blocks now meet different inputs, because what came before them differs, and the
pattern disappears:

```
ana@lab:~/lab$ openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -
ABCD EFGH IJKL MNOP QRST UVWX YZab cdef g
```

Thirty-three blocks and thirty-three letters. Two encrypted slots are now equal only by chance, and
with 2¹²⁸ possible blocks that chance is nil.

## CTR: AES as a stream of bytes

CTR, *counter mode*, uses AES differently. It never encrypts the data. It encrypts a counter, the
vector followed by 1, 2, 3 and so on, and combines the result with the data byte by byte using
XOR. AES becomes a generator of a **keystream**, and the data is mixed with that stream:

```
ana@lab:~/lab$ openssl enc -aes-256-ctr -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -
ABCD EFGH IJKL MNOP QRST UVWX YZab cdef
```

Thirty-two blocks this time, not thirty-three: CTR needs no padding, because the stream is cut to
the exact length of the data. It is also parallel in both directions, since block 20 can be
encrypted or decrypted without touching block 19, which CBC cannot do when encrypting.

The price is a rule with no exceptions: **a counter value may never be used twice with the same
key.** Two messages encrypted with the same key and the same starting value are mixed with the same
stream, and that leaks information about both plaintexts at once. Section 07 of this lesson is
about choosing that starting value, and lesson 17 is about how systems get it wrong.

## Which mode, then

- **ECB**: never, for anything longer than one block. The appointment file is the reason.
- **CBC**: legacy. Correct when the vector is random and a separate check protects the ciphertext.
  Neither of those happens by default, and the last section of this lesson shows why the check
  matters.
- **CTR**: fast and simple, but on its own it detects no change to the ciphertext either.
- **GCM**: CTR with a built-in check. This is what TLS 1.3, most disk formats and most libraries
  use by default, and it is where this lesson ends.

ChaCha20-Poly1305 is the other authenticated choice in TLS 1.3. It is a stream cipher, not AES,
and it is preferred on processors with no AES instructions, typically phones. Both are correct
choices; the important decision is to use one of the authenticated ones.
