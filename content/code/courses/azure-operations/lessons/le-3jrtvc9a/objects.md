---
title: Three kinds of object, and the two settings that keep them
version: 1
---

**A Key Vault holds three kinds of object**, and the difference between them is what the vault lets you do
with each:

| object | what it is | what you can do with it |
|---|---|---|
| **secret** | any value up to 25 KB: a password, a connection string, an API key | read it back, whole |
| **key** | a cryptographic key, RSA or elliptic curve | ask the vault to sign, verify, encrypt or decrypt with it; the private part never leaves |
| **certificate** | an X.509 certificate with its key | issue, renew and read the public part; the vault can renew it with a certificate authority |

The difference that matters most is the second row. **A secret is handed out; a key is used in place.**
An application that reads a secret has the secret in its memory, and so does anybody who compromises the
application. An application that signs with a key sends data to the vault and gets a signature back, and
the key itself cannot be stolen from it. The `premium` tier stores keys in hardware security modules;
`standard`, the shop's, stores them in software.

Two settings decide whether a deleted vault, or a deleted secret, can come back:

- **soft delete**: a deleted vault or object is kept for a retention period, 7 to 90 days, and can be
  recovered. It is on by default for new vaults and cannot be turned off;
- **purge protection**: during that period, **nobody can purge**, which means delete for good, not even an
  Owner. Once on, it cannot be turned off.

Purge protection sounds like an inconvenience and is the point. Without it, somebody holding a
compromised administrator account can delete the vault and then purge it, and every key that encrypted
the shop's data is gone with no way back. With it, the worst they can do waits 90 days for somebody to
notice. Lesson 16 listed a vault without it as a finding; the next section fixes it in Bicep.
