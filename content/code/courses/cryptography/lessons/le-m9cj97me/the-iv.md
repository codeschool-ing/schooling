---
title: The initialisation vector, and why it changes every time
version: 1
---

**Encryption with a fixed key, a fixed vector and a fixed plaintext gives a fixed ciphertext.** That
sounds harmless and is not: it means an observer can tell when the same message is sent twice,
without decrypting either. The initialisation vector exists to break that, and it only works if it
is different every time.

## The same letter, three times

Here is the referral letter encrypted three times with the same key: twice with the vector in
`iv-a.hex`, once with the vector in `iv-b.hex`. The fingerprint of each ciphertext (a SHA-256 hash,
the subject of lesson 4) is enough to compare them:

```
ana@lab:~/lab$ for iv in iv-a iv-a iv-b; do openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/$iv.hex) -in data/referral.txt | sha256sum; done
a7b407d99a56b97554234ebc20be68db5ebdd9a35e1e0fe6a992664ba245ba64  -
a7b407d99a56b97554234ebc20be68db5ebdd9a35e1e0fe6a992664ba245ba64  -
3b88e135a7ac10ac7a0137ad9801623d89766aaf62ca9159e8acd3067faa4c43  -
```

The first two are identical. Anybody who stores or watches Vereda's encrypted letters would learn
that two of them are the same letter, and with fields like a diagnosis code or a yes or no answer,
"the same as that other one" is often the whole secret. The third is unrelated to the first two
although the letter and the key did not change. **That is what a vector is for: the same plaintext
under the same key never produces the same ciphertext twice.**

## Not secret, but never reused

The vector is **not a secret**. Decryption needs it, so it travels with the ciphertext, usually as
its first sixteen bytes, and anybody can read it. What it must be depends on the mode:

| mode | name used | what it must be |
|---|---|---|
| CBC | IV | **unpredictable**: random, drawn fresh for each message |
| CTR | nonce or initial counter | **unique** for the key: never the same value twice |
| GCM | nonce, 12 bytes | **unique** for the key, and a repeat is worse than in CTR |

The difference between *unpredictable* and *unique* is real. A CBC vector that an outsider can
guess before a message is sent, for example the last block of the previous message, let the BEAST
attack on TLS 1.0 learn plaintext in 2011, and that is one reason TLS 1.1 changed to an explicit
random vector per record. A CTR or GCM nonce, by contrast, may be a simple counter, 1, 2, 3, as long
as it never repeats under the same key. TLS 1.3 builds each record's nonce from a sequence number
for exactly that reason: a counter cannot repeat while the connection lasts.

## How a real system chooses one

In this lab the vectors are files with fixed values, so that the transcripts come out the same for
you. **A real program never writes a vector down.** It asks the operating system's random number
generator for a fresh one at the moment it encrypts, through `os.urandom`, `crypto/rand`,
`SecureRandom` or `openssl rand`, and stores it beside the ciphertext:

```sh
iv=$(openssl rand -hex 16)
openssl enc -aes-256-cbc -K "$key" -iv "$iv" -in letter.txt -out letter.enc
printf '%s' "$iv" > letter.enc.iv
```

Two practical limits follow from the table:

- **A random 12-byte GCM nonce can collide by chance** after very many messages under one key. NIST
  SP 800-38D caps a key at 2³² messages with random nonces; past that, the key is replaced. A
  counter has no such limit, but it needs the counter to survive restarts, which is where systems
  usually fail (lesson 17).
- **The language's ordinary random function is not a source of vectors.** `random.random()` in
  Python and `Math.random()` in JavaScript are predictable by design: they are built to repeat a
  simulation, not to surprise anybody. Only the cryptographic generator will do.

Most libraries remove the choice. The modern interfaces of Python's `cryptography`, Go's
`crypto/cipher` and libsodium either generate the nonce for you or name it so loudly that passing
a constant looks wrong. Prefer the interface that removes the decision.
