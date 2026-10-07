---
title: The one question that tells them apart
version: 1
---

**To decide whether something is encrypted, ask: is there a secret key, and who holds it?** If there
is no key, it is encoding. If the key travels with the data or ships inside the software that reads
it, it is obfuscation. Only when the key is kept somewhere the reader of the data cannot reach is it
encryption.


```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A decision tree with one question: is there a secret key? No: encoding, reversible by anybody. Yes, but it ships with the data or inside the software: obfuscation, reversible by anybody with the software. Yes, and it is kept apart from the data: encryption, reversible only by whoever holds the key.\"><defs><marker id=\"q-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"240\" y=\"16\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">is there a secret key?</text><polyline points=\"300,56 120,120\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><text x=\"185\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no</text><polyline points=\"420,56 480,76\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><text x=\"462\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yes</text><rect x=\"20\" y=\"122\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">encoding</text><text x=\"120\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">anybody reverses it</text><rect x=\"400\" y=\"78\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">where does the key live?</text><polyline points=\"480,114 370,140\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><text x=\"380\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">with the data or the software</text><polyline points=\"620,114 620,138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#q-ah-wire)\"></polyline><rect x=\"250\" y=\"142\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">obfuscation</text><text x=\"350\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">anybody with the software</text><rect x=\"500\" y=\"142\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">encryption</text><text x=\"600\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only who holds the key</text><text x=\"628\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">apart from both</text></svg>", "caption": "One question about the key decides which of the three you are looking at."}
```

## The same password, actually encrypted

Here is the scheduler's password sealed with AES-GCM under a key that, in a real system, would live
in a secrets manager rather than beside the file:

```
ana@lab:~/lab$ printf 'V-db-s3cret-2026' > db-password.txt; vcrypt seal --key keys/aes-256.hex --nonce 0000000000000000000000d1 db-password.txt db-password.gcm
sealed db-password.txt: 12-byte nonce + 16 bytes of ciphertext + 16-byte tag -> db-password.gcm
```

Stored as text, the result is Base64 again, and looks no more mysterious than the Kubernetes Secret:

```
ana@lab:~/lab$ base64 -w0 db-password.gcm; echo
AAAAAAAAAAAAAADReYwrJG5TfYQM8/zMJWhgXKwvqnPe0cNCairT6G/wxo8=
```

But decoding the Base64 gives only bytes: the 12-byte nonce (zeros and `321` here, the lab's fixed
value), then ciphertext and tag:

```
ana@lab:~/lab$ base64 -w0 db-password.gcm | base64 -d | od -c | head -2
0000000  \0  \0  \0  \0  \0  \0  \0  \0  \0  \0  \0 321   y 214   +   $
0000020   n   S   } 204  \f 363 374 314   %   h   `   \ 254   / 252   s
```

Nothing in those bytes leads back to the password without the key. With it, the password returns:

```
ana@lab:~/lab$ vcrypt open --key keys/aes-256.hex db-password.gcm; echo
V-db-s3cret-2026
```

So **the encrypted version is only as secret as the key**. Put `aes-256.hex` in the same directory as
the configuration, in the same repository or in the same container image, and this is obfuscation
again, with better mathematics.

## The test as a table

| | example | key | who can reverse it |
|---|---|---|---|
| **encoding** | Base64, hex, PEM, URL encoding | none | anybody |
| **obfuscation** | ROT13, XOR with a constant, minified code | inside the software | anybody with the software |
| **hashing** | SHA-256, Argon2id | none, and nothing comes back | nobody reverses it; candidates can be tested (lesson 5) |
| **encryption** | AES-GCM, RSA-OAEP | kept apart from the data | only who holds the key |

Hashing has its own row because it is the other common confusion: "the passwords are encrypted with
SHA-256" mixes two different things. A hash cannot be decrypted by anybody, including its owner, and
whether it protects anything depends on the work of lesson 5.

## Reading a system with the test

When a document, a vendor or a colleague says data is "encrypted", the useful follow-up questions are
all about the key: which algorithm, where is the key, who and what can read the key, how is it
rotated. If nobody can answer the second question, the data is not encrypted in any sense that
matters, and lessons 14 and 17 are about building the answer properly.
