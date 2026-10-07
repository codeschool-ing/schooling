---
title: Encryption at rest, and the theft it stops
version: 1
---

**Encryption at rest protects stored data from somebody who obtains the storage without the key: a
stolen laptop, a disk thrown away, a backup tape lost in transit, a snapshot copied out of a cloud
account.** It is the encryption that compliance documents ask for most often, and the one most often
credited with protection it does not give.

## Layers, and who each one stops

Data at rest can be encrypted at several layers, and each layer has a different moment at which it
is decrypted, which decides who it protects against:

| layer | example | decrypted when | protects against |
|---|---|---|---|
| **disk or volume** | LUKS, BitLocker, FileVault, cloud volume encryption | the machine is unlocked | theft of the device or the disk |
| **database files** | TDE in SQL Server, Oracle, MySQL; encrypted cloud databases | the database server starts | theft of data files and backups |
| **column or field** | pgcrypto, application-level AEAD | the application, or a query with the key | database administrators, SQL injection that reads tables, leaked dumps |
| **file or object** | encrypted backups, S/MIME (lesson 13), age, GPG | the holder of the key opens it | anybody who is not that holder |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four layers stacked from bottom to top: the disk or volume, decrypted when the machine is unlocked; the database files, decrypted when the database starts; a column, decrypted only by a query or application holding its key; and a single file or object, decrypted only by the holder of its key. Each layer is transparent to everything above it once decrypted.\"><defs><marker id=\"lay-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"210.0\" y=\"20\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a file or object</text><text x=\"360\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only the key holder opens it</text><rect x=\"180.0\" y=\"72\" width=\"360\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a column</text><text x=\"360\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only a query or app with the key</text><rect x=\"150.0\" y=\"124\" width=\"420\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the database files (TDE)</text><text x=\"360\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">when the database starts</text><rect x=\"120.0\" y=\"176\" width=\"480\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the disk or volume</text><text x=\"360\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">when the machine is unlocked</text><text x=\"20\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decrypted later, trusted by fewer</text><polyline points=\"14,210 14,26\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#lay-ah-phosphor)\"></polyline></svg>", "caption": "The higher the layer, the later it is decrypted, and the fewer people it trusts."}
```

**Each layer is transparent to everything above it.** Full-disk encryption is invisible to the
operating system once it is unlocked, and so to every program and every user of the running machine.
That transparency is what makes it cheap to deploy, and it is also its limit: malware running on an
unlocked laptop reads files exactly as the owner does. The next sections take the layers in order,
and the last one is about the key, which decides whether any of them is worth anything.

## What encryption at rest never covers

- **The running system.** Data in memory, in use by a program, is decrypted. Protecting it is the job
  of access control and patching, not of storage encryption.
- **Data in transit.** That is TLS and the protocols of lessons 10 to 13.
- **Somebody with the key.** An attacker who steals the disk and the passphrase written on a sticky
  note beside it has both halves.

For Vereda, the concrete risks are a physiotherapist's laptop left in a taxi, the clinic's NAS sent
for repair, and the nightly database backup copied to a cloud bucket. Each section names which of
those it covers.
