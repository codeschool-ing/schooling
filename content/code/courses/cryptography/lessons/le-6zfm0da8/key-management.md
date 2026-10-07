---
title: Key management: envelope encryption and where the key lives
version: 1
---

**Every layer in this lesson is as strong as the custody of its key. The arrangement that has won
almost everywhere is envelope encryption: data encrypted with a data key, data keys encrypted
with a master key, and the master key in a service that never lets it out.** The structure is the
LUKS header of section 03 and the hybrid scheme of lesson 3, applied to a whole organisation.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Envelope encryption. On the left, the data, encrypted with a data key. Beside it, the data key wrapped by the master key. The master key stays inside the key management service. To read, the service holding the wrapped key asks the KMS to unwrap it, gets the data key back, decrypts locally and forgets it; the KMS checks permission and logs the request.\"><defs><marker id=\"env-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"env-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"330\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"36\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">storage: disk, bucket, backup</text><rect x=\"40\" y=\"66\" width=\"140\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">data</text><text x=\"110\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AES-256-GCM</text><text x=\"110\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">under the DEK</text><rect x=\"200\" y=\"96\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">wrapped DEK</text><text x=\"265\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32 bytes + tag</text><rect x=\"470\" y=\"50\" width=\"230\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">KMS or HSM</text><rect x=\"500\" y=\"90\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">master key (KEK)</text><text x=\"585\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks permission, logs</text><polyline points=\"332,112 468,100\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#env-ah-wire)\"></polyline><text x=\"400\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">unwrap?</text><polyline points=\"468,140 332,132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#env-ah-phosphor)\"></polyline><text x=\"400\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">DEK, briefly</text></svg>", "caption": "The master key never leaves the KMS; only wrapped data keys travel."}
```

## Two kinds of key

- A **data encryption key** (DEK) encrypts data: a disk, a database file, a column, one backup. It is
  random, used locally because the data is large, and stored only in **wrapped** form, encrypted, beside
  the data it protects.
- A **key encryption key** (KEK), or master key, encrypts DEKs and nothing else. It lives in a **key
  management service** (AWS KMS, Google Cloud KMS, Azure Key Vault, HashiCorp Vault) or a **hardware
  security module**, and the operation it offers is "unwrap this DEK for me", answered only to callers
  with permission, and logged.

To read data, a service sends the wrapped DEK to the KMS, gets the plain DEK back, decrypts locally
and forgets the DEK. The master key never leaves the KMS.

## What the arrangement buys

- **Access becomes a permission, with an audit trail.** Who can decrypt the database backups is the
  list of identities allowed to call unwrap on one key, and every call is logged. A leaked backup is
  useless to anybody who cannot also call the KMS as an authorised identity.
- **Rotation is cheap.** Rotating the master key means re-wrapping DEKs, a few hundred bytes each, not
  re-encrypting terabytes.
- **Crypto-erase at scale.** Deleting a DEK makes its data unreadable everywhere it was copied: a
  customer's data, a retired system's backups. Deleting a master key does that for everything under
  it, so KMS products put a waiting period of days on deletion.
- **Separation of duties.** The people who administer the database are not the people who control
  the key policy.

## Three rules a review checks

1. **A key is never stored beside what it protects.** Not in the same configuration file, the same
   repository, the same image or the same bucket. Lesson 11's test applies to every layer of this one.
2. **A key that would be catastrophic to lose has a recovery path**, tested: LUKS's recovery slot,
   escrowed encryption keys (lesson 3), KMS keys protected from deletion. Encryption with no recovery
   turns a lost key into lost data, which under the LGPD is an incident too.
3. **Backups are encrypted with keys that the production systems cannot delete.** Ransomware that
   reaches production should not be able to destroy, or re-encrypt, the backups' keys as well.

Lesson 17 starts from the first rule, because breaking it is the commonest cryptographic mistake there
is.
