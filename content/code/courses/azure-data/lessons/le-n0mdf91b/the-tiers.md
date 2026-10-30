---
title: What an access tier trades
version: 1
---

**An access tier is a price for keeping a gigabyte paired with a price for reading it back**, and
each tier below hot buys a lower first price with a higher second one. People tend to read the list
as "fast, slower, slowest", as if the cheaper tiers were slower disks. Three of the four are not.
Hot, cool and cold all answer a read in milliseconds; what changes between them is the bill for the
read, the bill for the write, and the bill for leaving early. Only archive is slow, and there the
blob cannot be read at all until it is brought back.

This section is taught from Microsoft's documentation on access tiers for blob data, and none of it
can be seen on Azurite, which stores every blob the same way whatever its tier says.

## The four tiers

| tier | for data that is | minimum days billed | first byte |
|---|---|---|---|
| hot | read or written often | none | milliseconds |
| cool | read rarely, kept at least a month | 30 | milliseconds |
| cold | read very rarely, kept at least a season | 90 | milliseconds |
| archive | kept for a long time and almost never read | 180 | hours, after a rehydration |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The four access tiers and the minimum number of days each one bills. Hot has no minimum, cool 30 days, cold 90 and archive 180. Hot, cool and cold return the first byte in milliseconds; archive returns nothing until the blob is rehydrated, which takes hours.\" data-fig=\"l04-tiers\"><defs><marker id=\"l04-tiers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">tier</text><text x=\"150\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">minimum days billed</text><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Hot</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">first byte: milliseconds</text><text x=\"154\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">none</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Cool</text><text x=\"20\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">first byte: milliseconds</text><rect x=\"150\" y=\"104\" width=\"90.0\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"232.0\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">30</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Cold</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">first byte: milliseconds</text><rect x=\"150\" y=\"156\" width=\"270.0\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"412.0\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">90</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Archive</text><text x=\"20\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">first byte: hours, after a rehydration</text><rect x=\"150\" y=\"208\" width=\"540.0\" height=\"24\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"682.0\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">180</text><path d=\"M150.0 260 L150.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"150.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M240.0 260 L240.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"240.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M420.0 260 L420.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"420.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90</text><path d=\"M690.0 260 L690.0 266\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"690.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">180</text><path d=\"M150 260 L690 260\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"690\" y=\"294\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">days</text></svg>", "caption": "The minimum days and the latencies are Microsoft's documented figures; none of them can be seen on Azurite."}
```

**The tier is a property of each block blob**, not of the container or the account. One container
can hold yesterday's export in hot, last quarter's in cool and the 2019 audit files in archive, side
by side under the same prefixes. The account has a **default access tier**, hot unless somebody
chose another, and a block blob uploaded without a tier takes it; the next section shows the
difference between a tier that was set and one that was inferred.

**Only block blobs have these tiers.** Lesson 2 said so, and the next section shows Azurite
refusing a tier on an append blob. Page blobs on premium accounts have performance tiers named `P10`,
`P20` and so on, which are a different thing with the same word.

## What changes on the bill

Lesson 1's price sheet prints each tier's meters, and lesson 7 is about operations and transfer, so
the shape is enough here. Going down the table, from hot to archive:

- **the price of keeping a gigabyte for a month falls**, and it falls a long way: the archive is the
  cheapest storage Azure sells for blobs;
- **the price of each operation rises**, writes and reads both, so a tier change on millions of small
  blobs can cost more than the storage it saves;
- **cool, cold and archive add a price per gigabyte read back**, which hot does not charge at all;
- **the minimum days are billed even if the blob leaves early**, deleted, overwritten or moved to
  another tier; the section on early deletion does the arithmetic.

Two things that sound like tiers are not. **Premium** is the account's performance (lesson 1), solid
state disks for a whole account, not a tier a blob can move into. And the Terraform provider in this
course accepts a fifth value for an account's default, `Smart`, as the next section prints. By
Microsoft's description it moves blobs between the online tiers according to how they are used. It
is newer than the rest of this lesson, it is not covered here, and nothing in this course ran it.
