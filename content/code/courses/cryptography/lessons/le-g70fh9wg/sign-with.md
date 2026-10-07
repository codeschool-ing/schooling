---
title: To prove authorship, sign with your own private key
version: 1
---

**A signature is made with the signer's private key and checked with the signer's public key.**
Only the holder of the private key could have produced it, and anybody holding the public key can
check it. That is the second job, and it uses the pair the other way round from the previous
section: the secret key is now on the sender's side.

## Ana signs the referral

Ana's clinic sends referrals to Vereda, and Vereda wants to know that a referral really came from
Ana and was not changed on the way. Ana signs the letter with her Ed25519 private key:

```
ana@lab:~/lab$ openssl pkeyutl -sign -rawin -inkey keys/ed25519-ana.key -in data/referral.txt -out referral.sig
ana@lab:~/lab$ od -An -tx1 referral.sig
 71 23 41 e1 5e 79 68 83 2b 55 e1 59 a6 58 0a b6
 81 31 38 e8 77 b5 eb 8d b0 e8 63 fb 58 f3 00 13
 de b0 6f 7d 4e 5c 63 7c 3d 06 9a 12 62 c3 f9 a7
 65 dd cc 1b 4a 8f 73 d5 ed dc 3a 11 8c 51 5e 08
```

The signature is 64 bytes, the fixed size for Ed25519 that lesson 2 measured. Ed25519 is
deterministic, so signing the same letter again gives exactly these bytes; that is why the
transcript is the same on your machine.

Vereda checks it with Ana's **public** key, which it obtained earlier through a channel it trusts:

```
ana@lab:~/lab$ openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-ana.pub -in data/referral.txt -sigfile referral.sig
Signature Verified Successfully
```

## What a signature catches

The signature covers every byte of the letter. Somebody changes the number of sessions from eight
to twelve and keeps Ana's signature:

```
ana@lab:~/lab$ sed "s/Eight sessions/Twelve sessions/" data/referral.txt > altered.txt
ana@lab:~/lab$ openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-ana.pub -in altered.txt -sigfile referral.sig
Signature Verification Failure
```

And the right letter checked against somebody else's public key fails too, because Bruno's key
did not make this signature:

```
ana@lab:~/lab$ openssl pkeyutl -verify -rawin -pubin -inkey keys/ed25519-bruno.pub -in data/referral.txt -sigfile referral.sig
Signature Verification Failure
```

Those two failures are the two guarantees a signature gives:

- **integrity**: the letter is byte for byte the one that was signed;
- **authenticity**: it was signed by the holder of the private key matching the public key used
  to check it.

A third follows from the second, and it is what makes signatures different from the shared-key
checks of lesson 6: **non-repudiation**. Only Ana holds her private key, so Ana cannot later claim
that Vereda produced the signature itself. With a key both sides share, either side could have.

## What a signature does not do

Look again at the signed letter: it is `data/referral.txt`, unchanged and readable. **Signing hides
nothing.** The signature travels beside the message, and the message stays as readable as it was.
A signed e-mail, a signed software package and a signed certificate are all public; the signature
says who stands behind them, not who may read them.

And the guarantee is only as good as the public key used to check it. Had Vereda received
"Ana's public key" from an attacker, it would have checked the attacker's signatures and accepted
them. Which public key belongs to whom is the question certificates answer, in lessons 8 and 9.
