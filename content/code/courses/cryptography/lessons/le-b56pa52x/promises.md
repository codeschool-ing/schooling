---
title: What a hash function promises
version: 1
---

**A cryptographic hash function turns input of any length into a fixed-length output, the
*digest*, and it is built so that nobody can work backwards from the digest or find two inputs
that share one.** It has no key. Anybody can compute the hash of anything, and that is the point:
it is a public fingerprint, and the fingerprint is useful because it cannot be forged.

## This lesson's files

One new thing, a stand-in for a software release: Vereda's portal, version 2.4.1, as 20,480 bytes
from `vcrypt derive` rather than a real program, a note about it, and the file of digests a project
publishes beside a release, which section 05 reads. Here you make that file yourself, as whoever
publishes the release would:

```sh
cd ~/lab
mkdir -p data/release
vcrypt derive --raw release/portal-2.4.1 20480 > data/release/portal-2.4.1.tar
echo 'Vereda portal 2.4.1: booking reminders by SMS.' > data/release/NOTES.txt
(cd data/release && sha256sum NOTES.txt portal-2.4.1.tar > SHA256SUMS)
```

## Fixed length, whatever goes in

SHA-256 always returns 256 bits, 64 hexadecimal digits. The 170-byte letter, the 512-byte
appointment file, the 20,480-byte release and a megabyte of zeros all come out the same size:

```
ana@lab:~/lab$ sha256sum data/referral.txt data/slots.dat data/release/portal-2.4.1.tar
7c55ba550e02c3e33d50f2e4627f5e855b6cc9692e91eb72d15e5905f32abc4c  data/referral.txt
5e832af18cbeab6bd7bb6d2931668e0296498d2e5837980aee5e5d49ae3f8750  data/slots.dat
7a3cfae88053ea853e98e2211769a0cf9f605d6f761aff2878059628177a6a3f  data/release/portal-2.4.1.tar
ana@lab:~/lab$ head -c 1000000 /dev/zero | sha256sum
d29751f2649b32ff572b5e0a9f541ea660a50f94ff0beedfb0b692b924cc8025  -
```

That is what makes a digest useful as a fingerprint: it can be stored in a column, printed on a
download page or put in a signature, whatever the size of what it describes.

## One letter, a different fingerprint

Two inputs that differ by one letter give unrelated digests:

```
ana@lab:~/lab$ printf 'Eight sessions' | sha256sum
b40d32921f905e70f8414b6d7c06a112852fbbf0cd2856efe91981013a3f54fc  -
ana@lab:~/lab$ printf 'Eight session' | sha256sum
22c197768e113d6dbf8eacd22417f12c7ce5b2f17f5408d23e587896e8384c61  -
```

There is no partial resemblance to exploit, no "nearly the same" digest for "nearly the same"
input. A short tool counts how many of the 256 bits two digests disagree on:

```py
# ~/lab/tools/avalanche.py
"""vcrypt avalanche A B: SHA-256 of two strings, and how many of the 256 bits
differ between the two digests."""
import hashlib
import sys

a, b = sys.argv[1], sys.argv[2]
ha, hb = hashlib.sha256(a.encode()).digest(), hashlib.sha256(b.encode()).digest()
print(f"{a!r:>20}  {ha.hex()}")
print(f"{b!r:>20}  {hb.hex()}")
print(f"{sum(bin(x ^ y).count('1') for x, y in zip(ha, hb))} of 256 bits differ")
```

Lowercasing one letter changes about half of them:

```
ana@lab:~/lab$ vcrypt avalanche 'Eight sessions' 'eight sessions'
    'Eight sessions'  b40d32921f905e70f8414b6d7c06a112852fbbf0cd2856efe91981013a3f54fc
    'eight sessions'  c26b06836dfea0538e1300682b618f3560cc64346e2579b6f98059ca850651c5
132 of 256 bits differ
```

132 of 256 is what chance looks like, and that is the property called the **avalanche effect**: a
change anywhere in the input spreads over the whole output.

## The three promises

A cryptographic hash makes three promises. Each is about what an attacker cannot do, and each
protects a different use:

| promise | what nobody can do | what breaks if it fails |
|---|---|---|
| **preimage resistance** | given a digest, find any input that produces it | hashes used to hide a value |
| **second-preimage resistance** | given an input, find a different one with the same digest | checking a known file against its published hash |
| **collision resistance** | find any two inputs with the same digest | signatures and certificates |

The last one is the hardest to keep, for a reason that is pure arithmetic. A digest of *n* bits
has 2ⁿ possible values. Finding a preimage takes about 2ⁿ attempts, but finding **any** two inputs
that collide takes only about 2ⁿ/² (the *birthday bound*: in a room of 23 people, two probably
share a birthday). So a 256-bit hash gives 128 bits of collision resistance, the security level of
lesson 2's table, and a 128-bit hash like MD5 gave only 64 at best.

## Collisions exist, and that is not the failure

A function from inputs of any length to 256 bits must have collisions: there are infinitely many
inputs and only 2²⁵⁶ digests. The promise is not that collisions do not exist. **The promise is
that nobody can find one.** When somebody can, faster than the birthday bound, the hash is broken
for every use that relies on that promise, which is exactly what happened to MD5 and SHA-1 and is
the subject of section 04 of this lesson.

What a hash is not: it is **not encryption**, because nothing comes back out of it, and it is
**not a password store** on its own, because for short guessable inputs the attacker does not need
to reverse anything, only to try candidates. Lesson 5 is about that difference.
