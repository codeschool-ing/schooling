---
title: The mix-ups, and how to tell them apart
version: 1
---

**Four operations, two key pairs, and one question settles every case: what is the operation
protecting, and from whom?** The mistakes below are common in documentation, in interviews and in
code, and each one has led to a real design that protected the wrong thing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A two-by-two grid. Columns: whose key, mine or the other party&#x27;s. Rows: public key or private key. The other party&#x27;s public key encrypts a secret for them. My private key signs. The other party&#x27;s private key is never mine to hold. My public key lets others verify me, and encrypt to me.\"><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mine</text><text x=\"530\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the other party&#x27;s</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">public</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">private</text><rect x=\"120\" y=\"40\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">others verify my signatures</text><text x=\"250\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and encrypt to me</text><rect x=\"400\" y=\"40\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">I ENCRYPT a secret for them</text><text x=\"530\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">only their private key opens it</text><rect x=\"120\" y=\"130\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"250\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">I SIGN with it</text><text x=\"250\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and decrypt what was sent to me</text><rect x=\"400\" y=\"130\" width=\"260\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"530\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never in my hands</text></svg>", "caption": "Which key, for which job, seen from the sender's side."}
```

## "Signing is encrypting with the private key"

This sentence is everywhere, and it is true only of textbook RSA, where the same arithmetic runs in
both directions. It is false for the algorithms in current use: ECDSA and Ed25519 cannot encrypt
anything, and RSA signatures use PSS padding that encryption does not. Thinking of signing as
"encryption" leads to the next mistake, so it is worth dropping the phrase altogether. **Signing
produces a proof attached to a message; it does not transform the message.**

## "The message is signed, so it is confidential"

A signature hides nothing, as section 03 showed: the letter stayed readable beside its signature. A
team that signs its configuration files has protected them from being altered, not from being read.
If the content is secret, it also needs encrypting.

## "The message decrypted correctly, so it came from the right person"

Anybody can encrypt to a public key. A records service that accepts any request it can decrypt
accepts requests from everybody on the internet. **Decryption proves nothing about the sender**;
only a signature, or the shared-key check of lesson 6, does.

## "One key pair can do both jobs"

It can, mathematically, with RSA. It should not. A pair used for signing and a pair used for
receiving encrypted data have different lives:

- an **encryption key** must be recoverable: if it is lost, every message encrypted to it is lost,
  so organisations escrow it;
- a **signing key** must never be escrowed: if a copy exists elsewhere, non-repudiation is gone,
  because somebody else could have signed.

So the two are separate pairs, and certificates say which job each key is for (the *key usage*
field of lesson 9).

## "Encrypting with my own public key is pointless"

It is not. Encrypting to your own public key gives a file that only your private key opens, and the
encrypting machine needs no secret to do it. A backup server can encrypt every night to a public key
whose private half is offline in a safe; a thief who takes the backup server takes nothing that
decrypts the backups. Lesson 14 builds that arrangement.

## The rule in one table

| I want to… | I use… | the other side uses… |
|---|---|---|
| send a secret to somebody | **their public key** | their private key, to decrypt |
| prove I wrote something | **my private key** | my public key, to verify |
| both | sign with mine, then encrypt to theirs | decrypt with theirs, then verify with mine |
