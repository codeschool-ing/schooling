---
title: Where the prices in this course come from
version: 1
---

**Every price in this course was read from Google's public pricing pages on 30 October 2026, in US
dollars, for the São Paulo region, `southamerica-east1`, unless the sentence says otherwise.** Each
one is quoted with the page it came from and the unit it is charged in, and every total is shown as
a calculation you can run. Prices move on Google's schedule rather than this course's, so a number
here is a fact about that date, and the page is where to check today's.

## Why there is no program that fetches them

Google publishes its prices in two places. The **pricing page of each product**, such as
`cloud.google.com/storage/pricing`, is a document for people, with a table per region. The **Cloud
Billing Catalog API** is the same list for programs: every service, every *SKU* (a stock-keeping
unit, Google's word for one priced thing, such as "Standard Storage São Paulo") and every tier. The
API is the right tool, and it needs an API key, which needs a project, which needs an account. So
this course reads the pages and writes the date down, and never shows a number it did not read
there.

**Three things on a pricing page decide what a line costs**, and each is a way to misread it:

- **The region.** The same storage costs a different amount in São Paulo and in Iowa, and the page
  shows one region at a time.
- **The unit.** Storage is charged per **GiB-month**, a gibibyte (2³⁰ bytes, not 10⁹) kept for a
  month, and computed from what is stored at each moment. Operations are charged per thousand,
  BigQuery queries per tebibyte, and a machine per hour or per second.
- **The free part.** Some lines have an allowance that is not charged, and some allowances apply
  only to some regions. The Standard storage line for Iowa is marked as having one; the line for São
  Paulo is not.

## The first two prices

From `cloud.google.com/storage/pricing`, read on 2026-10-30: Standard storage in a single region
costs **$0.035 per GiB-month in São Paulo** and **$0.02 in Iowa**, `us-central1`. A tebibyte for a
month in each:

```
ana@laptop:~/gcp$ python3 -c 'print(round(1024 * 0.035, 2), round(1024 * 0.020, 2))'
35.84 20.48
```

**$35.84 against $20.48, 75% more for keeping the same bytes in Brazil.** That gap is the first
decision this course prices. Keeping Quitanda's data in São Paulo is not free, and moving it to Iowa
is not either: lesson 5 shows that reading data out of a region costs money, and Brazil's data
protection law, the LGPD, sets conditions on sending a customer's personal data abroad. Cheapest is one property of a
region, and the lessons treat it as one among several.

The same page charges for **operations**, per thousand requests, by class. For a bucket in one region
in the Standard class, a **Class A** operation (one that writes or lists, such as an upload) costs
**$0.005 per thousand**. A **Class B** operation (one that reads, such as a download or a
metadata read) costs **$0.0004 per thousand**. One upload a minute for thirty days, and a million
reads:

```
ana@laptop:~/gcp$ python3 -c 'print(round(30 * 24 * 60 * 0.005 / 1000, 2), round(1_000_000 * 0.0004 / 1000, 2))'
0.22 0.4
```

**Twenty-two cents and forty cents**, which is why operations are invisible on a bill full of large
files and the whole bill on one full of small ones. Lesson 5 is about the second case.

## The bill, without a bill

**Every lesson that makes a choice prices it**, because on Google Cloud a design and its invoice are
the same decision. A table partitioned by the wrong column is a table every query reads whole, and a
Spanner instance sized for the peak is an instance paid for at the peak all month. Cost is the one
thing in this subject that is learnt by feeling it, and this course cannot make you feel it,
because nothing in it ever touches a real account. It does the next best thing: the price is read
from the page, the arithmetic is shown, and the number is checkable rather than asserted.

The money in this course is therefore always a calculation and never an invoice. That is safer and
honest about what it is, and it is not the same as watching a real total climb overnight.
