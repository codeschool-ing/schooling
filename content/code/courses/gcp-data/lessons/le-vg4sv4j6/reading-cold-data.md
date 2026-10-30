---
title: Reading an Archive object back
version: 1
---

**An object in Archive is read like any other object, at once.** There is no restore request, no
waiting copy and no tier of speed to choose. People who have used a tape archive, or another cloud's
archive class, expect the opposite: an object that is listed and cannot be opened until somebody asks
for it hours in advance. In Cloud Storage the price of Archive is paid in money and in a 365-day
minimum stay, not in time.

The bucket from the previous section still holds the Archive copy. Read it:

```
ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-archive-prod/orders/2026-09/archive.csv | head -3
order_id,customer_id,total_cents
ord-09-1,c-1,997
ord-09-2,c-2,1004
ana@laptop:~/gcp$ gcloud storage cp gs://quitanda-archive-prod/orders/2026-09/archive.csv back.csv && wc -c back.csv
Copying gs://quitanda-archive-prod/orders/2026-09/archive.csv to file://back.csv
  

10295 back.csv
ana@laptop:~/gcp$ gcloud storage restore --help | sed -n '/^DESCRIPTION/,/^EXAMPLES/p' | head -8
DESCRIPTION
    The restore command restores soft-deleted resources:

        $ gcloud storage restore url...

EXAMPLES
ana@laptop:~/gcp$ python3 -c 'print(1024 * 0.01, 1024 * 0.02, 1024 * 0.05)'
10.24 20.48 51.2
```

**The emulator served the Archive copy at once, all 10,295 bytes**, and here it behaves as Cloud
Storage does. The `restore` that the command line does have is something else: its help says it
restores soft-deleted resources, objects deleted from a bucket that keeps them for a while, which is
lesson 3's subject. Nothing in `gcloud storage` restores an archived object, because nothing needs to.

What the emulator cannot show is the bill for that read. The last command above is what reading a
whole tebibyte back would cost in retrieval fees alone: 10.24 USD from Nearline, 20.48 from Coldline
and 51.20 from Archive. On top of that comes one Class B operation per object read, at the price of
its class, and the network, when the data leaves Google's network or the region, which lesson 5
prices.

Three details of the fee, from the pricing page, decide how it lands:

- **it is charged on the bytes served, not on the object's size.** A program that reads the first
  8 MB of a 100 MB Nearline object pays the fee on 8 MB, and so does a download that breaks after
  8 MB;
- **copying, moving and rewriting are reads too.** The page says the fee applies when you "read,
  copy, move, or rewrite" an object stored in the three colder classes, so the class change of the
  previous section, made from Coldline or Archive, pays a retrieval fee as well as the rewrite;
- **it does not apply in a bucket with Autoclass on**, which the next section is about.

## What the milliseconds mean for a design

**A class that reads at once moves the line between "archive" and "keep handy".** Quitanda's audit
exports belong in Archive, and so does something an archive in hours could never hold: the photos a
courier takes at each delivery, read only when a customer disputes one, months later, and needed
while the customer is on the phone. The question to ask of a set of files is no longer how soon they
are needed. It is how often they are read and for how long they are kept, because those are the two
things the bill depends on.

## The delivery photos, priced

Say the photos are 300 KB each and Quitanda takes two million of them a year. The command below gives
their size in GiB, then for Standard and for Archive what that volume costs to keep for twelve months
and what the two million uploads cost in Class A operations:

```
ana@laptop:~/gcp$ python3 -c 'gib = 2_000_000 * 300_000 / 2**30; print(round(gib, 1)); [print(c, round(gib * p * 12, 2), round(2_000_000 / 1000 * a, 2)) for c, p, a in (("Standard", 0.035, 0.005), ("Archive", 0.003, 0.05))]'
558.8
Standard 234.69 10.0
Archive 20.12 100.0
```

**Archive keeps the year's 558.8 GiB for 20.12 USD against Standard's 234.69, and costs ten times as
much to write**: 100 USD of uploads against 10. Over the first year Archive still wins, 120.12 against
244.69, and it keeps winning every year after, because the photos are written once and kept. A
dispute reads five photos, five Class B operations at 0.05 per thousand and 1.5 MB of retrieval at
0.05 per GiB, and neither of those reaches a cent. The bill of a cold class is decided by how many
objects are written and how many bytes are read, and here both are small.

The same arithmetic turns the other way for data written in tiny pieces and read in bulk, which is a
click stream. That is why the class is decided per kind of data, and why one bucket can hold several.
