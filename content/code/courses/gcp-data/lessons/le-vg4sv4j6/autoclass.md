---
title: Autoclass, and the fee for being managed
version: 1
---

**Autoclass is a bucket setting that moves each object between classes by itself**, according to
when it was last read, and charges a monthly fee per object for doing it. It is the answer to "we do
not know how this data will be read", and it is the wrong answer for small objects, because the fee
is per object and the saving is per gibibyte.

Google's documentation for Autoclass, cloud.google.com/storage/docs/autoclass, describes it like
this. Every object starts in Standard. After 30 days without being read it moves to Nearline, and if
the bucket's terminal class is Archive, on to Coldline after 90 days and to Archive after 365. The
terminal class is Nearline unless the bucket asks for Archive. A read moves the object back to
Standard. A life-cycle rule that changes classes cannot sit beside Autoclass in the same bucket,
because the two would be deciding the same thing.

The pricing page adds what it costs, and it is a different bill from the rest of this lesson:

- **no retrieval fees and no early-deletion charges** for objects in an Autoclass bucket, which is
  what makes the moves safe to make automatically;
- **a management fee of 0.0025 USD for every 1,000 objects** kept for 30 days;
- **objects smaller than 128 KiB are not managed and not counted**. They stay in Standard for as long
  as they exist, at Standard's price;
- **operations are charged at Standard's rate** in such a bucket, and a move from Coldline or Archive
  back to Standard or Nearline is billed as a Class A operation;
- **turning Autoclass on for a bucket that already holds objects has a one-time charge**: the early
  deletions and retrievals of moving every object to Standard, and a Class A operation per object.

## In the emulator

Quitanda's log bucket is the candidate: application logs, read often for a week and then hardly
ever, with nobody able to say which ones. Create it with Autoclass and Archive as the terminal class:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-logs-prod --location=southamerica-east1 --enable-autoclass --autoclass-terminal-storage-class=ARCHIVE
Creating gs://quitanda-logs-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-logs-prod --format=json
{
  "creation_time": "2026-10-30T15:30:35-0300",
  "default_storage_class": "STANDARD",
  "location": "southamerica-east1",
  "location_type": "region",
  "metageneration": 1,
  "name": "quitanda-logs-prod",
  "storage_url": "gs://quitanda-logs-prod/",
  "update_time": "2026-10-30T15:30:35-0300",
  "versioning_enabled": false
}
ana@laptop:~/gcp$ curl -s http://localhost:4443/storage/v1/b/quitanda-logs-prod | grep -c -i autoclass
0
```

**The bucket was created and the setting was not kept.** The command line sent it, the emulator
answered with success, and neither the `describe` nor the emulator's own answer about the bucket
mentions Autoclass at all: the last command counted the word in its reply and found it zero times.
fake-gcs-server 1.54.0 does not implement Autoclass, and it does not say so. Nothing in this section
depends on running it; what follows is arithmetic on the documented prices.

## The fee against the object

The smallest object that pays the fee is 128 KiB. Its storage in Standard, in São Paulo, is
128 / 1,048,576 GiB × 0.035, and its fee is 0.0025 / 1,000 a month:

```
ana@laptop:~/gcp$ python3 -c 'keep = 128 / 1024**2 * 0.035; fee = 0.0025 / 1000; print(f"{keep:.8f} {fee:.8f} {fee / keep:.0%}")'
0.00000427 0.00000250 59%
ana@laptop:~/gcp$ python3 -c 'keep = 1 / 1024 * 0.035; fee = 0.0025 / 1000; print(f"{keep:.8f} {fee:.8f} {fee / keep:.1%}")'
0.00003418 0.00000250 7.3%
```

**For a 128 KiB object the fee is 59% of the price of keeping it in Standard.** Even if Autoclass
moved it to Archive on the first day, where it would cost 0.003 instead of 0.035, the fee alone
would keep the object above half of what Standard charges. At 1 MiB the fee is 7.3% of Standard's
price, and at 100 MiB well under a tenth of a per cent. Autoclass pays for itself on large objects
whose future is unknown: the Parquet files of a data lake, which lesson 17 queries in place. It does
not pay on Quitanda's logs if they are written as one small object per request, and the honest
first step there is to write fewer, larger objects. A life-cycle rule, which lesson 3 writes, does
the same moves for a known pattern with no fee, and an object it moves does not come back by itself.

## Autoclass or a life-cycle rule

The two do overlapping jobs, and the choice between them is a question about what you know:

| | Autoclass | life-cycle rule |
|---|---|---|
| decides from | when each object was last read | how old each object is, and other conditions |
| moves an object back to Standard | yes, on a read | never |
| retrieval and early-deletion fees | none | the class's own, on reads and early deletes |
| cost of running it | 0.0025 USD per 1,000 objects of 128 KiB or more, per 30 days | nothing, beyond each move's Class A operation |

**Use a rule when the pattern is known, and Autoclass when it is not.** Quitanda's order exports are
read for a month and then almost never, on a calendar everybody knows, and a rule moves them for
nothing. The data lake's files are read whenever an analyst has a question, and nobody can say which
file will be next. There Autoclass is worth its fee, because a file that is suddenly popular again
goes back to Standard instead of paying Archive's 0.05 a GiB on every read.
