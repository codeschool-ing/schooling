---
title: CPU allocation, and the two ways to be billed
version: 1
---

Cloud Run offers two answers to the question of when an instance has a CPU. **By default the CPU is
allocated only while a request is being processed, and the instance is billed only for that time.**
The alternative is a CPU for the whole life of the instance, billed for the whole life, at a lower
rate. Choosing between them is arithmetic, and the price sheet has the numbers.

## Request-based billing

With the default, an instance that is not serving a request is **throttled to almost no CPU**. It
still exists, holds its memory and its open connections, and answers the next request at once, but
between requests it cannot do anything useful. You pay for the time from the start of the first
request to the end of the last one in progress, rounded up to 100 milliseconds, plus a price per
request.

This is what makes the background work of lesson 10's warning fail. A service that answers and
then keeps working to send an email or write a report is doing that work with a CPU Cloud Run has
just taken away. It may finish minutes later, or when the next request arrives, or not at all if
the instance is shut down first. **Work after the response belongs in a job or a queue**, lesson
20's Cloud Tasks, not in the tail of a request.

## Instance-based billing

With `cpu_idle = false`, called "CPU always allocated" in gcloud, the instance has its CPU for its
whole life and is billed for its whole life, idle or not, with no per-request price. Background work
then runs normally. The rates are lower per second, because Google is selling time it can plan for:

```
ana@laptop:~/gcp$ python3 prices.py serverless | head -12
Google Cloud public prices, us-central1, USD, 30 October 2026

Cloud Run, request-based billing (cloud.google.com/run/pricing)
  vCPU, while a request is being served             0.000024  per vCPU-second
  memory, while a request is being served          0.0000025  per GiB-second
  vCPU, an idle minimum instance                   0.0000025  per vCPU-second
  requests                                               0.4  per million
  free each month: vCPU                               180000  vCPU-seconds
  free each month: memory                             360000  GiB-seconds
  free each month: requests                          2000000  requests

Cloud Run, instance-based billing, and jobs
```

## Which costs less

The difference is only the share of the instance's life spent serving. This program works out both
for one instance of 1 vCPU and 512 MiB, at the sheet's prices. Save it as `~/gcp/runcost.py`:

```python
# runcost.py
"""What one Cloud Run instance of 1 vCPU and 0.5 GiB costs in a month,
billed by request or by instance, for the share of the month it is busy.
Prices from prices.py, lesson 1; requests and the free tier left out."""
import sys

VCPU, GIB = 1, 0.5
SECONDS = 730 * 3600                     # the month of the price sheet
busy = float(sys.argv[1])                # 0.25: serving a quarter of the time

by_request = busy * SECONDS * (VCPU * 0.000024 + GIB * 0.0000025)
by_instance = SECONDS * (VCPU * 0.000018 + GIB * 0.000002)
idle_minimum = (1 - busy) * SECONDS * (VCPU * 0.0000025 + GIB * 0.0000025)
print(f'busy {busy:4.0%}: by request {by_request:6.2f} USD, '
      f'plus {idle_minimum:5.2f} kept as a minimum instance; '
      f'by instance {by_instance:6.2f} USD')
```

And run it for an instance busy 5% of the month up to busy all the time:

```
ana@laptop:~/gcp$ for b in 0.05 0.25 0.50 0.75 1.00; do python3 runcost.py $b; done
busy   5%: by request   3.32 USD, plus  9.36 kept as a minimum instance; by instance  49.93 USD
busy  25%: by request  16.59 USD, plus  7.39 kept as a minimum instance; by instance  49.93 USD
busy  50%: by request  33.18 USD, plus  4.93 kept as a minimum instance; by instance  49.93 USD
busy  75%: by request  49.77 USD, plus  2.46 kept as a minimum instance; by instance  49.93 USD
busy 100%: by request  66.36 USD, plus  0.00 kept as a minimum instance; by instance  49.93 USD
```

**Instance-based costs the same whatever the instance does**, 49.93 dollars a month for this size.
Request-based grows with the work: 3.32 at 5% busy, 33.18 at half. They cross between half and
three quarters; at 75% busy request-based is 49.77 and at 100% it is 66.36, a third dearer. The
middle column is section 05's subject: what keeping the instance as a warm minimum costs on top of
request-based billing in the hours it is idle.

So **a service that is busy most of the time is cheaper with the CPU always allocated**, and one
that is busy now and then is cheaper with the default. Two things the program leaves out move the
line a little: the per-request price, 0.40 dollars a million, which only request-based pays; and the
monthly free tier of the sheet, which gives instance-based billing more vCPU-seconds than
request-based billing, and which a small service can live inside entirely.
