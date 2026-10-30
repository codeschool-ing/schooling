---
title: The minimum days, and the bill for leaving early
version: 1
---

**A blob in cool, cold or archive is billed for its tier's minimum days whether it stays or not.**
That is how Microsoft's documentation describes the early deletion charge: a blob deleted,
overwritten or moved to another tier before its minimum is charged for the days that remain, at the
price of the tier it left. People read the minimum as a rule that stops them deleting. Nothing stops
them; the deletion succeeds at once, and the remaining days arrive on the bill.

This section is taught from that documentation. Azurite has no bill, and deletes a blob that moved to
cold a few minutes earlier without a word; the blob it deletes is the September export the earlier
sections set to cold:

```
ana@laptop:~/azure$ az storage blob delete -c orders-archive -n orders/2026-09/default.csv
ana@laptop:~/azure$ az storage blob list -c orders-archive --prefix orders/2026-09/ --query "[].[name, properties.blobTier]" -o tsv
orders/2026-09/audit.csv	Archive
orders/2026-09/cool.csv	Hot
```

The deletion printed nothing and the blob is gone from the listing. On Azure the same command would
succeed the same way, and the 90 days of cold would be billed in full.

## The arithmetic

The charge is prorated: the remaining days, at the tier's monthly price. With an illustrative cool
price of 0.010 USD per GB-month, which is a round number for the sum and not Azure's price:

| what happens | days kept | days billed | one GB, illustrative |
|---|---|---|---|
| moved to cool, deleted after 10 days | 10 | 30 | 0.010 |
| moved to cool, deleted after 45 days | 45 | 45 | 0.015 |
| moved to archive, moved to hot after 30 days | 30 | 180 | at archive's price, for 180 days |

The first row is the one that surprises people: ten days of storage cost as much as thirty. The
second has no charge at all, because the minimum was passed. The third is the expensive mistake,
because archive's minimum is six months: a blob archived by a rule on Monday and needed on Friday pays
for half a year of archive and then the rehydration on top.

## What it means for a design

**Put data in a cooler tier only when you know how long it will stay.** That is a question about the
data, and Quitanda can answer it. The nightly exports are read by the finance team for about a month
and kept seven years for the tax authority; they belong in hot for the first month, cool after it,
and archive once nobody has read them for a year. The click files of lesson 3 are rewritten into
daily tables within a week and deleted; they never belong anywhere but hot, because every cooler tier
would bill them for days they never lived.

Moving blobs by hand stops working at the second thousand of them. Lesson 5 hands the job to a
life-cycle rule, which moves and deletes by age, and knows nothing about the minimum days either:
a rule that archives at 30 days and deletes at 90 pays archive's 180 for every blob it touches.
