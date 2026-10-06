---
title: HMAC, a hash with a key in it
version: 1
---

**An HMAC is a hash computed over a message together with a secret key, so that only somebody
holding the key can compute it or check it.** It is defined in RFC 2104 and works with any hash;
HMAC-SHA256 is the common choice. The output is called a **tag**, and it is what the gateway sends
with each message.

## The tag of the real message, and of the forged one

With the shared key in `keys/webhook.hex`, the tag of the genuine notice:

```
ana@lab:~/lab$ openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) data/webhooks/evt-1.json
HMAC-SHA2-256(data/webhooks/evt-1.json)= 2e62aade7c551522eb97c60dee626384a62e4926bef81ea646754f0c9847c6d1
```

And the tag of the forged one, with the amount changed to 120:

```
ana@lab:~/lab$ openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) forged.json
HMAC-SHA2-256(forged.json)= 0936c48c8fb16e7785b635099d19463cda9f35509653dc882df41caff39c9b2f
```

The two tags are unrelated, as lesson 4's avalanche effect promised. What matters is who can produce
them. The forger has the forged body but not Vereda's key. If they compute an HMAC with any other key,
here the lab's AES key standing in for a guess, they get a third, equally unrelated tag:

```
ana@lab:~/lab$ openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/aes-256.hex) forged.json
HMAC-SHA2-256(forged.json)= d473f2538cbcbb4d33f8ca0aafac5df230279de37cc172be85ac5346f604ea35
```

It does not match what the portal computes with the real key, so the forged message is refused.
**Without the key, there is no way to produce the right tag for a changed message**, and with a
256-bit key there is no way to guess it.

## Why not just SHA-256(key + message)?

It looks equivalent and is not. Lesson 4 described the length-extension property of SHA-256:
whoever knows the digest of a message can compute the digest of that message with bytes appended,
without knowing the message. With the key at the front, that means extending the message and
producing a valid check **without the key**. HMAC avoids it by hashing twice, with the key mixed in
both times in a fixed way:

```
HMAC(K, m) = H( (K xor opad) || H( (K xor ipad) || m ) )
```

`ipad` and `opad` are two fixed constants, and `||` is concatenation. Nobody needs to remember the
formula. What is worth remembering is the conclusion: **never build a keyed check out of a plain
hash yourself.** Every language has HMAC in its standard library (`hmac` in Python, `crypto/hmac` in
Go, `javax.crypto.Mac` in Java, `crypto.createHmac` in Node), and it is the right tool.

## What a MAC does not give

An HMAC proves the message came from somebody holding the key. With a key shared between two
parties, that means "from the gateway, or from Vereda itself". For a webhook that is enough:
Vereda trusts itself. For a dispute with a third party it is not, because Vereda could have produced
any tag it shows. When that matters, the answer is a signature, in section 05.

AES-GCM, from lesson 1, contains a MAC of its own, the tag that refused the altered file. That is the
same idea built into a cipher: encryption plus a keyed check, under one key.
