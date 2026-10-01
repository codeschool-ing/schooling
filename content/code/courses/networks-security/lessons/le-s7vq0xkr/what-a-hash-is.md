---
title: A fingerprint for any amount of data
version: 1
---

A **cryptographic hash function** turns any input, one byte or a whole disk, into a fixed-length
value, its **digest**. SHA-256, the one used everywhere in this course, always produces 256 bits,
printed as 64 hexadecimal digits. Two instructions that differ in one character:

```
ana@laptop:~$ printf "transfer 100 to 4471\n" | sha256sum
b27a1ded929f467f0ca682df32680cff4a8285222ac4b386ddfe12b9ae362bfc  -
ana@laptop:~$ printf "transfer 900 to 4471\n" | sha256sum
c4f9711cc5c2cf98b63f8d91d382be4ea460e81fa1618e555448b2e4980e869e  -
```

One digit changed in the message and **nothing recognisable survives in the digest**. That is not a
coincidence of these two inputs; it is the design. And the length does not depend on the input: a
million zero bytes and nothing at all both give 64 digits:

```
ana@laptop:~$ head -c 1000000 /dev/zero | sha256sum; printf "" | sha256sum
d29751f2649b32ff572b5e0a9f541ea660a50f94ff0beedfb0b692b924cc8025  -
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  -
```

The last line is the digest of the empty input, `e3b0c442…`, the same on every computer, which makes
it easy to recognise in a log: something hashed a file that was empty.

Three properties make a hash useful for security, and each rules out an attack by name:

| property | means | rules out |
|---|---|---|
| **preimage resistance** | from a digest, you cannot find an input that produces it | recovering a message from its fingerprint |
| **second-preimage resistance** | given one input, you cannot find another with the same digest | swapping a file for a different one that checks out |
| **collision resistance** | you cannot find *any* two inputs with the same digest | preparing two documents in advance, one to show and one to use |

MD5 and SHA-1 were once used the same way, and **collisions have been demonstrated for both**. They
remain fine for spotting accidental corruption and are no longer acceptable where somebody might be
trying to fool the check. SHA-256 and its larger siblings, and SHA-3, are the current choices.

**A hash has no key.** Anybody can compute the digest of anything, which is exactly why a digest on
its own proves less than people assume. The next section shows how much less.
