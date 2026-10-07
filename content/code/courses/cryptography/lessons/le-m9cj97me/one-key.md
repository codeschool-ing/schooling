---
title: One key that locks and unlocks
version: 1
---

**Symmetric cryptography uses the same key to encrypt and to decrypt.** Whoever holds the key can
do both, and whoever does not hold it can do neither. Everything else in this lesson is about using
that one key well, because the mathematics of the cipher is the part that almost never fails.

## A letter, a key and the same key back

Vereda keeps a referral letter for every patient. Here is one, and here is the key the lab uses to
encrypt it:

```
ana@lab:~/lab$ cat data/referral.txt
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
ana@lab:~/lab$ cat keys/aes-256.hex
2273f51f3c00abbd6cc30ebc3339cf8b4798afb1786829887df8b0d8526250a0
```

The key is 32 bytes, written as 64 hexadecimal digits: **a 256-bit key**. It is nothing but random
bytes. There is no structure in it and no password behind it, and that is what makes it a key.
(The lab cheats here on purpose: it derives every key from a public label, so that these
transcripts come out the same on your machine. Lesson 17 shows why a key anybody can rebuild is
no key.) `openssl enc` encrypts the letter with AES and that key, and what comes out is bytes with no
visible relation to the letter:

```
ana@lab:~/lab$ openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/referral.txt -out referral.enc
ana@lab:~/lab$ od -An -tx1 -N48 referral.enc
 b7 9d 96 21 e6 9a 64 11 01 5e ab b6 c5 7a ff 12
 23 62 e3 f8 5a c8 ef 16 1e 51 d6 80 81 34 48 b8
 12 3c 90 4e 55 85 2f 1f 1e a8 43 4b 7e b7 0d b4
```

Decrypting needs the same two inputs, the key and the vector (`-iv`, the subject of section 07 of
this lesson). Given both, the letter comes back exactly:

```
ana@lab:~/lab$ openssl enc -d -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in referral.enc
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
```

Given **another** 256-bit key, it does not:

```
ana@lab:~/lab$ openssl enc -d -aes-256-cbc -K $(cat keys/aes-256-b.hex) -iv $(cat keys/iv-a.hex) -in referral.enc -out wrong.txt 2>err.txt; echo "exit status $?"; head -1 err.txt
exit status 1
bad decrypt
```

`bad decrypt` is OpenSSL noticing that the last block does not end the way a correctly decrypted
block must (the next section explains that ending, the padding). Read it as luck rather than as a
guarantee. Most wrong keys trip it, and a few produce garbage that happens to end correctly. A
cipher on its own has no way of saying "this is the wrong key"; it turns any input into some
output. Telling a correct decryption from garbage is a separate job, and the last section of this
lesson gives it to the mode.

## Why the key is the only secret

The algorithm is public. AES was chosen in an open competition run by NIST, its specification is
FIPS 197, and every line of OpenSSL is readable. This is deliberate and has a name, **Kerckhoffs's
principle**: a system must stay secure when everything about it except the key is known. A secret
algorithm adds nothing, because it leaks the first time a binary is copied, and it costs a great
deal, because nobody outside has been allowed to find its flaws. Lesson 17 returns to this as one
of the three classic mistakes.

So the strength of the scheme is the size of the key space. With 256 bits there are 2²⁵⁶ keys,
and trying them all is out of reach for any computer that can be built. Even 128 bits, 2¹²⁸ keys,
is far beyond every brute-force search anybody has run. **AES-128 is not weak**; AES-256 is chosen
for margin, and in particular for the future of lesson 7, where a quantum computer halves the
effective length of a symmetric key and 256 becomes 128.

## What symmetric cryptography cannot do by itself

One key for both directions is fast and simple, and it leaves one problem untouched: **the two
sides need the same key before they start**. Vereda's server can encrypt its own files with a key
only it knows. A patient's browser and that server, meeting for the first time, share nothing. How
they agree on a key over a network somebody may be listening to is lesson 7, and it needs the
asymmetric cryptography of lessons 2 and 3. Every real system combines the two: asymmetric to
agree on a key, symmetric to encrypt the data. That combination is what TLS is, in lesson 10.

The second thing it cannot do is **say who wrote something**. If Vereda and a laboratory share a
key, a message encrypted under it could have come from either of them. Lesson 6 separates proving
that a message is intact from proving who sent it.
