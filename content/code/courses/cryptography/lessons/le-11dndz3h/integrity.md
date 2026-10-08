---
title: A checksum anybody can recompute proves nothing
version: 1
---

**Integrity against accidents and integrity against an adversary are different properties.** A
checksum catches a cable that flipped a bit. It does not catch a person who changed the message,
because that person can recompute the checksum too. This lesson is about the second kind, and it
starts by showing why the first is not enough.

## This lesson's files

Vereda's portal and its payment gateway share a secret key, and the gateway sends four payment
notices signed with it. One program makes all four, playing the gateway's part; section 04 is about
checking what it writes, and the file is worth rereading then:

```py
# ~/lab/tools/deliveries.py
"""vcrypt deliveries: four deliveries from Vereda's payment gateway, written
into data/webhooks/ as a body (.json) and the header that came with it
(.sig). They are signed the way most payment gateways sign: an HMAC-SHA256
over "<timestamp>.<body>", sent as t=<timestamp>,v1=<hex>. The lab's
present is 1781535600, 2026-06-15 12:00 in Sao Paulo, and each delivery is
a different case:

  evt-1  a payment, signed 42 seconds ago
  evt-2  a payment whose amount was changed after it was signed
  evt-3  evt-1 again, signed a day ago: a replay
  evt-4  a refund, signed with a key that is not the gateway's
"""
import hashlib
import hmac
import os

import drbg


def sign(key: bytes, timestamp: int, body: bytes) -> str:
    tag = hmac.new(key, str(timestamp).encode() + b"." + body, hashlib.sha256).hexdigest()
    return f"t={timestamp},v1={tag}"


key = drbg.stream("webhook", 32)  # the same bytes as keys/webhook.hex
NOW = 1781535600
paid = b'{"event":"payment.confirmed","booking":4471,"amount":12000}'
paid2 = b'{"event":"payment.confirmed","booking":4472,"amount":15000}'
refund = b'{"event":"refund.issued","booking":4471,"amount":12000}'

os.makedirs("data/webhooks", exist_ok=True)
for name, body, header in (
    ("evt-1", paid, sign(key, NOW - 42, paid)),
    ("evt-2", paid2.replace(b"15000", b"1500"), sign(key, NOW - 37, paid2)),
    ("evt-3", paid, sign(key, NOW - 86400, paid)),
    ("evt-4", refund, sign(b"a key that is not the gateway's", NOW - 12, refund)),
):
    open(f"data/webhooks/{name}.json", "wb").write(body)
    open(f"data/webhooks/{name}.sig", "w").write(header + "\n")
```

Then the key, from `vcrypt derive` like every other key in the lab, and the deliveries:

```sh
cd ~/lab
vcrypt derive webhook 32 > keys/webhook.hex
vcrypt deliveries
```

## A payment notice, and a hash beside it

Vereda's portal learns that a patient has paid through a message from its payment gateway, a small
piece of JSON:

```
ana@lab:~/lab$ cat data/webhooks/evt-1.json; echo
{"event":"payment.confirmed","booking":4471,"amount":12000}
```

Suppose the gateway sent its SHA-256 alongside, so that the portal can check nothing was changed:

```
ana@lab:~/lab$ sha256sum data/webhooks/evt-1.json
29907c15a04982fb68cfa1836a41d97f53f33fb3b0fdef9c3b67077e560729bd  data/webhooks/evt-1.json
```

Now somebody between the gateway and the portal changes the amount from 12000 cents to 120 and
recomputes the digest:

```
ana@lab:~/lab$ sed 's/12000/120/' data/webhooks/evt-1.json > forged.json; sha256sum forged.json
4f9653ccf5a9c5a2474a9bb3b437fdda1c8d7ef322d2dfada0a3938f0f4bcebf  forged.json
```

The portal receives a body and a digest that match each other perfectly. Lesson 4 said this in
general: **a hash has no key, so whoever can change the message can change the hash.** The digest
proves the body was not damaged after the digest was computed. It says nothing about who computed it.

## What the portal actually needs

Two properties, which come together in practice:

- **integrity against an adversary**: if anybody changed the message, the check fails;
- **authenticity of origin**: the check can only have been produced by the gateway.

Both need something the attacker does not have, which means a key. There are two ways to use one:

| | shared secret key | key pair |
|---|---|---|
| mechanism | **MAC**, in practice HMAC | **digital signature**, lesson 3 |
| who can produce the check | anybody holding the shared key | only the holder of the private key |
| who can verify it | anybody holding the shared key | anybody holding the public key |
| proves to a third party who sent it | no: either side could have made it | yes: non-repudiation |
| cost | microseconds | far slower, and needs a public key to be trusted |

The gateway and Vereda already share a secret, issued when Vereda opened its account, so the
gateway uses the left column. A software release, checked by thousands of people who share nothing
with its author, uses the right one. The next three sections take them in that order.
