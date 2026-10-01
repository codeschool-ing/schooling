---
title: Reading the bill before it arrives
version: 1
---

A function is billed on two meters. **Requests count how many times it was called; GB-seconds count
how much memory it held and for how long.** A GB-second is one gigabyte of configured memory for one
second of running: a function set to 512 MB that runs for 120 ms uses 0.5 × 0.120 = 0.06 GB-seconds
per call. **The memory is what you configured, not what the code used**, and Lambda bills the
duration by the millisecond, rounded up.

These are the Lambda lines of the course's price sheet, the AWS public price list for `sa-east-1`
(São Paulo) and `us-east-1` (N. Virginia), in US dollars, excluding tax, at the offer versions the
sheet prints at the top:

```
ana@laptop:~/cloud$ python3 prices.py lambda
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Lambda, USD
  per 1 million requests                     0.20         0.20
  per GB-second, x86                 0.0000166667 0.0000166667
  per GB-second, Arm                 0.0000133334 0.0000133334
  free tier, requests                   1,000,000    1,000,000
  free tier, GB-seconds                   400,000      400,000
```

Three things in it deserve a second look. **The two regions charge the same for Lambda**, where the
EC2 lines of the same sheet make São Paulo dearer. The Arm rate is lower than the x86 one, for the
same code run on AWS's Arm processors, provided it and its libraries run on Arm. And the free tier is
in the list as two allowances, a million requests and 400,000 GB-seconds a month. The list shows
only the allowance; the terms of the free tier are on AWS's own pages, and this course does not
restate them.

## One month, worked in the open

A function answers an API: 3 million requests a month, 512 MB of memory, an average billed duration
of 120 ms, on x86.

- GB-seconds: 3,000,000 × 0.5 GB × 0.120 s = 180,000.
- Requests: 3 million × 0.20 USD per million = 0.60 USD.
- Duration: 180,000 × 0.0000166667 = 3.00 USD, or 3.000006 before rounding.
- Together: **3.60 USD a month, before the free tier.**

With the free tier subtracted, 2 million requests are billed, which is 0.40 USD, and 180,000
GB-seconds sit under the 400,000 allowance, so the duration costs nothing: 0.40 USD a month.

The same arithmetic as a program, so the numbers can be changed and run again:

```schooling-example
{"language": "python", "file": "bill.py", "parts": [{"code": "# Lambda, x86, from `python3 prices.py lambda`: the same in both regions.\nPER_MILLION_REQUESTS = 0.20\nPER_GB_SECOND = 0.0000166667\nFREE_REQUESTS = 1_000_000\nFREE_GB_SECONDS = 400_000\n", "note": "Four lines of the price sheet, copied as they are. The rate per GB-second is the x86 one; on Arm this line would read `0.0000133334`."}, {"code": "requests = 3_000_000          # a month\nmemory_gb = 512 / 1024        # 512 MB\nseconds = 0.120               # average billed duration\n", "note": "The three facts about the workload. Memory is what you configured, and 512 MB is half of the 1,024 MB counted to a gigabyte."}, {"code": "gb_seconds = requests * memory_gb * seconds\nreq_cost = requests / 1_000_000 * PER_MILLION_REQUESTS\ngbs_cost = gb_seconds * PER_GB_SECOND", "note": "**The two Lambda meters**, each times its own price. The API gateway, the logs and the data sent out are billed by their own services and are not here."}, {"code": "print(f\"GB-seconds          {gb_seconds:>12,.0f}\")\nprint(f\"requests            {req_cost:>12.2f} USD\")\nprint(f\"GB-seconds          {gbs_cost:>12.2f} USD\")\nprint(f\"total, no free tier {req_cost + gbs_cost:>12.2f} USD\")\n", "note": "Printed with thousands separators and two decimal places, which is where 3.000006 becomes 3.00."}, {"code": "req_left = max(0, requests - FREE_REQUESTS)\ngbs_left = max(0, gb_seconds - FREE_GB_SECONDS)\nfree_total = req_left / 1_000_000 * PER_MILLION_REQUESTS + gbs_left * PER_GB_SECOND\nprint(f\"total, free tier    {free_total:>12.2f} USD\")", "note": "Each allowance comes off its own meter, never below zero: the requests past the first million are billed, and 180,000 GB-seconds are all inside the 400,000."}], "output": "GB-seconds               180,000\nrequests                    0.60 USD\nGB-seconds                  3.00 USD\ntotal, no free tier         3.60 USD\ntotal, free tier            0.40 USD"}
```

**These are the Lambda meters and nothing else.** The API gateway in front of the function, the
logs it writes and the data it sends to the internet are billed by their own services, and none of
them is in this total. Lesson 10 is about finding lines like those before they arrive.

The 3.60 moves with the workload in ways you can read off the meters. Twice the requests is twice
the bill. Twice the memory, or twice the duration, doubles the duration part. And **a function that
spends 100 ms of its 120 waiting on a database is billed for the waiting**, because GB-seconds count
the time the environment was held, not the time the processor worked. On a machine you already pay
for by the hour, a slow query costs latency; here it costs money as well.
