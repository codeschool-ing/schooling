---
title: One shared key, or a pair
version: 1
---

Cryptography in a network does two jobs that people often blur together: keeping a message
**secret** from whoever carries it, and **agreeing on a secret** with somebody you have never met. Two
families of algorithm exist because those are different problems.

| | symmetric | asymmetric |
|---|---|---|
| keys | one key, shared by both ends | a pair per party: a private key kept, a public key given out |
| what it does well | encrypts large amounts of data, fast | agrees on a secret, and signs (lesson 11), without a shared secret beforehand |
| its hard part | both ends need the key before they start, and nobody else may have it | slow, and only as good as knowing whose public key you hold (lesson 12) |
| algorithms met in this course | AES, ChaCha20 | X25519, RSA, ECDSA, Ed25519 |

**The common wrong picture is that asymmetric encryption is the "stronger" kind** and used for
everything important. It is used for almost nothing in bulk. Every protocol this course touches, TLS,
SSH, WireGuard, uses asymmetric cryptography for a few milliseconds at the start, to agree on a
symmetric key, and symmetric cryptography for every byte after that. The rest of this lesson shows
each half on the lab, then the two together in a tunnel between the head office and the branch.

A last word on sizes, because they are compared constantly and badly: **key lengths only compare
within a family**. A 256-bit AES key and a 256-bit elliptic-curve key are both considered strong; a
2048-bit RSA key is roughly as strong as a 112-bit symmetric key, not eight times stronger than AES.
