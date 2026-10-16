---
title: What a trail costs
version: 1
---

```
ana@laptop:~/aws$ python3 price.py AWSCloudTrail EventsRecorded
AWSCloudTrail, sa-east-1, published 2026-09-11
  SAE1-DataEventsRecorded                  0.000001 USD per Events     0.000001 per data event recorded in South America(Sao Paulo) region
  SAE1-FreeEventsRecorded                  0.000000 USD per Events     0.0 per free event recorded in South America(Sao Paulo) region
  SAE1-NetworkEventsRecorded               0.000001 USD per Events     $0.000001 per network activity events recorded in South America (Sao Paulo)
  SAE1-PaidEventsRecorded                  0.000020 USD per Events     0.00002 per paid event recorded in South America(Sao Paulo) region
```

**The first copy of management events is free**, `FreeEventsRecorded`: one trail recording them in each
region costs only the bucket. A second trail recording the same management events pays the `Paid` line,
2 USD per 100,000. **Data events are 1 USD per million**, and network activity events the same. Lake and
Insights have lines of their own, priced per gigabyte ingested and per event analysed.

The shop's trail, for a month:

| line | quantity | USD a month |
|---|---|---|
| management events, first copy | 1.5 million | 0.00 |
| data events, the orders bucket only | 3 million × 0.000001 | 3.00 |
| S3, the files | about 2 GB | cents |
| **total** | | **about 3** |

The same data events on **every** bucket would be the line to watch: a bucket serving 500 million object
reads a month adds 500 USD for recording them, which is why the selector of the first section named one
bucket. And a second trail, made by somebody who did not know the first existed, doubles the management
events from free to 30 USD a month: `describe-trails` across the organisation is the first thing to run
when that line appears.
