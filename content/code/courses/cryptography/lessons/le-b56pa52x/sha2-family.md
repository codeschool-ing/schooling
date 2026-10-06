---
title: The families, and which ones are current
version: 1
---

**Four families of hash functions are in everyday use, and only two of them are fit for security
today: SHA-2 and SHA-3.** MD5 and SHA-1 are still installed everywhere and still computed every
day, which is why they keep turning up where they should not. The lab's letter, hashed by each:

```
ana@lab:~/lab$ for h in md5 sha1 sha256 sha512 sha3-256; do printf "%-9s %s\n" $h $(openssl dgst -$h -r data/referral.txt | cut -d" " -f1); done
md5       332f92433f21aa59ed87b03193c49e82
sha1      88fd3a934445ac8893896ddc006ec0c41f275248
sha256    7c55ba550e02c3e33d50f2e4627f5e855b6cc9692e91eb72d15e5905f32abc4c
sha512    36bbfbbcda296d46d3c4ce9e9c090cb768262aec6727bf7e73a8419eab4b3adf0b032aee4917739e455bc5e518a48be59eff6ced89a2579a307fefa3da435a0c
sha3-256  c99600ac85b5605d9d8e78d0319c3fdafa11b09bfa150abe70263a942a020a71
```

The length of the digest is the first thing that tells them apart:

```
ana@lab:~/lab$ for h in md5 sha1 sha256 sha512 sha3-256; do printf "%-9s %3s bits\n" $h $(( $(openssl dgst -$h -r data/referral.txt | cut -d" " -f1 | tr -d "\n" | wc -c) * 4 )); done
md5       128 bits
sha1      160 bits
sha256    256 bits
sha512    512 bits
sha3-256  256 bits
```

## The four families

| family | year | digest | status |
|---|---|---|---|
| **MD5** | 1992 | 128 bits | broken for collisions since 2004; never for security |
| **SHA-1** | 1995 | 160 bits | broken for collisions since 2017; being retired everywhere |
| **SHA-2** (SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/256) | 2001 | 224 to 512 bits | **current**; SHA-256 is the default almost everywhere |
| **SHA-3** (SHA3-256, SHA3-512, SHAKE) | 2015 | 224 to 512 bits | **current**; a different design, kept as a reserve |

SHA-2 and SHA-1 share an internal construction, called Merkle–Damgård: the input is processed in
blocks, each one mixed into a running state, and the final state is the digest. When SHA-1 showed
weaknesses in 2005, nobody could be sure SHA-2 would not follow, so NIST ran a public competition
for something built differently. Keccak won and became SHA-3 in 2015, with a *sponge*
construction that shares nothing with SHA-2. SHA-2 has held up since, so SHA-3 is not a
replacement but a spare: if SHA-2 ever falls, the next standard is already in the libraries.

Outside NIST, **BLAKE2** and **BLAKE3** are fast, modern hashes used inside WireGuard, Argon2
(lesson 5) and many file-synchronisation tools. They are sound choices where a standard does not
require SHA-2.

## A property of SHA-256 that matters later

Because SHA-256 and SHA-512 output their entire internal state, anybody who knows the digest of a
message and its length can compute the digest of that message **with more bytes appended**,
without knowing the message. This is the *length-extension property*. It does not break any of
the three promises of the previous section, and it is harmless for checksums and signatures. It
matters in one specific misuse: building a check as `SHA-256(secret + message)`, where somebody
could extend the message and produce a valid check without the secret.

SHA-512/256 (SHA-512 with its output truncated), SHA-3 and BLAKE2 do not have this property. But
the real answer is not to pick a hash that avoids it: it is to never build a keyed check by hand,
and to use **HMAC**, which lesson 6 builds and which is safe with any of these hashes.

## Which name to type

For anything new, `sha256` is the answer unless a standard says otherwise: `sha256sum` on the
command line, `hashlib.sha256` in Python, `crypto/sha256` in Go. Use SHA-384 or SHA-512 where a
profile asks for 192 or 256 bits of security, typically alongside P-384 or AES-256 in government
profiles. **MD5 and SHA-1 are for reading old data and nothing else.**
