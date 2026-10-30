---
title: Custom types and shared cores
version: 1
---

Two kinds of machine type step outside the three ratios. **A custom type lets you name your own
vCPUs and memory, and a shared-core type sells you less than one vCPU.** Each is the right answer
in one situation and an expensive habit in the others.

## Custom types, priced from their parts

A custom type is written as the series, the word `custom`, the vCPUs and the memory **in MiB**:
`n4-custom-4-10240` is four vCPUs and 10 GiB. It is priced per vCPU and per GiB, and the program
in section 03 multiplies the two:

```
ana@laptop:~/gcp$ python3 prices.py custom n4 4 10
Google Cloud public prices, us-central1, USD, 30 October 2026

n4-custom-4-10240: 4 vCPU and 10 GiB
  4 x 0.03275 per vCPU                                 0.131  per hour
  10 x 0.003717 per GiB                              0.03717  per hour
  together                                           0.16817  per hour
  together, for 730 hours                             122.76  per month
```

Against `n4-standard-4`, which has 16 GiB and costs 132.42 a month, the custom type saves 9.66
dollars by not carrying 6 GiB nobody asked for. That is the case custom types exist for: **the
ratio you measured falls between two predefined ones, and the gap is worth paying to close.**

Now ask for the other end of the range, 32 GiB on four vCPUs:

```
ana@laptop:~/gcp$ python3 prices.py custom n4 4 32
Google Cloud public prices, us-central1, USD, 30 October 2026

n4-custom-4-32768: 4 vCPU and 32 GiB
  4 x 0.03275 per vCPU                                 0.131  per hour
  32 x 0.003717 per GiB                             0.118944  per hour
  together                                          0.249944  per hour
  together, for 730 hours                             182.46  per month
```

**182.46 a month, against 173.77 for `n4-highmem-4`**, which has the same four vCPUs and the same
32 GiB and is on the same page. The difference is a premium Google states on its price page: the
on-demand price of a custom type is 5% above the predefined type it imitates. So a custom type
that lands exactly on a predefined shape is simply the predefined shape, dearer. Check the
catalogue before writing `custom`.

Three rules shape what you may ask for, and Compute Engine checks them when it creates the
machine, not when Terraform plans it:

- **memory comes in multiples of 256 MiB**, which is why the name carries MiB rather than GiB;
- each series has a **range of memory per vCPU**, and on N4 the normal range ends at 8 GiB per
  vCPU;
- above that range is **extended memory**, which the series that allow it charge at a higher
  rate per GiB, 0.008745975 an hour on N4 against 0.003717 inside the range.

## Shared cores

`e2-micro`, `e2-small` and `e2-medium` show **2 vCPUs** on the sheet, and that number is the
ceiling, not the allowance. Each one is entitled to a fraction of a vCPU over time, a quarter for
`e2-micro`, half for `e2-small` and one whole vCPU for `e2-medium`, and may burst above it for
short periods when the host has room. The rest of the time it is held to its share.

That makes them the cheapest machines on the sheet, 6.11 a month for `e2-micro`, and right for
work that is mostly waiting: a small internal tool, a bastion host, a machine that wakes up for a
cron job. It makes them wrong for anything whose load is steady, because a steady load is exactly
what the burst cannot cover. A web server that is busy all afternoon on an `e2-small` is a web
server that is slow all afternoon, and nothing on the bill says so.

Google's free tier includes one `e2-micro` a month in a few regions in the United States, which
makes it the usual first machine of a personal account. It is one possibility among several, it
is not offered in São Paulo, and it changes on Google's schedule, so read the current terms
before you count on it.

## Which one to reach for

| the situation | the type |
|---|---|
| the measured ratio matches a predefined type | the predefined type |
| it falls between two, and the gap is large | a custom type |
| it needs more memory per vCPU than any standard ratio | `highmem`, then a custom type with extended memory |
| the load is light and mostly idle | a shared-core E2 |
| the load is steady | never a shared core |
