---
title: Rotation, destruction and the cost of a key
version: 1
---

**A key version's life has four states, and the last one cannot be undone.** **Enabled** versions encrypt and
decrypt. **Disabled** ones do neither and can be enabled again at once. **Scheduled for destruction** ones are
disabled with a countdown, 30 days by default, during which the destruction can be cancelled. **Destroyed** ones
are gone, and the data they wrapped with them, as `rm kek/v1.bin` showed. Nothing in this section ran against
Cloud KMS; the destruction was shown with a file in the second section.

## The safeguard is the delay

Destroying a version in Cloud KMS does not happen when it is asked for:

```sh
gcloud kms keys versions destroy 1 --key=orders --keyring=shop --location=southamerica-east1
```

That command (not run) schedules version 1 for destruction, and the version is destroyed only when the scheduled
period ends. The period is set per key when the key is created, from 1 to 120 days, 30 by default. **Thirty days is
the window in which somebody notices**: a job that fails to read last month's exports, a restore test that cannot
decrypt a backup. A log-based alert (lesson 10) on the audit entry for `DestroyCryptoKeyVersion` makes sure
somebody notices on the first day rather than the twenty-ninth. Cancelling is one command,
`gcloud kms keys versions restore`, which leaves the version disabled, to be enabled once the reason is understood.

## Rotation, again, with the real service

Automatic rotation adds a version on the schedule and makes it primary; nothing is re-encrypted, as the second
section showed. For CMEK, Cloud Storage and the other services use the primary version for new writes and the
recorded version for reads, so a bucket written over two years holds objects wrapped by eight different versions,
all readable, all needed. **Never destroy an old version to tidy up**, unless the data it wraps is meant to be
gone. Re-encrypting old data under the new version is a separate job, a rewrite of every object, and it is only
worth doing when a version is suspected of being compromised.

## What a key costs

From the pricing page, read on 30 October 2026: each **active** software key version costs **0.06 USD a month**,
and active includes enabled, disabled and scheduled for destruction; cryptographic operations cost **0.03 USD per
10,000**, after 10,000 free a month; administrative operations are free. HSM versions cost more.

The shop's `orders` key, rotated every quarter, has four active versions after a year: 0.24 USD a month. If
every read of an exported order needed one unwrap, 100,000 reads a month would be 90,000 operations above the free
allowance, 0.27 USD. **Envelope encryption is why this is cheap**: Cloud KMS is
asked for a few bytes of key per object, never for the object itself, whatever its size.
