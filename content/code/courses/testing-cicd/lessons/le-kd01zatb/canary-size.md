---
title: How much traffic is enough to judge
version: 1
---

Two more runs, at the same 10%, with a hundred requests each:

```
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 100 5001
backend    requests errors    rate
blue             92      0    0.0%
green             8      0    0.0%
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 100 6001
backend    requests errors    rate
blue             89      0    0.0%
green            11      1    9.1%
ana@laptop:~/shipquote$ sed -i 's/"blue": 90, "green": 10/"blue": 100, "green": 0/' ~/envs/routes.json
```

In the first, green answered 8 requests without an error, and looked perfect. In the second it
answered 11 and failed one: 9.1%, which looks catastrophic. The release was the same both times,
and so was its bug. **Neither number says anything**, because neither rests on enough requests.

## The arithmetic

Green fails one order in twenty of this mix, a rate of 5%. The chance that a single request
succeeds is therefore 0.95, and the chance that *n* requests in a row all succeed is 0.95 multiplied
by itself *n* times:

| requests on green | chance of seeing no error at all |
| --- | --- |
| 8 | 66% |
| 20 | 36% |
| 50 | 8% |
| 102 | 0.5% |

With eight requests, a canary with this bug looks clean two times out of three. To have a 95%
chance of seeing at least one error, green needs 59 requests, because 0.95 to the power 59 is just
under 0.05. A bug that fails one request in a thousand needs about three thousand.

## What follows from it

- **Wait for a count, not for a clock.** "Ten minutes at 10%" means a different amount of evidence at
  noon and at three in the morning. `ops/canary.py` refuses to judge a side that has answered fewer
  than 50 requests, and says so when it carries on.
- **A small service needs a bigger share, or a longer wait.** A canary at 1% of a service that takes
  ten requests a minute sees one request in ten minutes.
- **One error is not a verdict either.** The 9.1% above was a single failure. A rule that stops on
  any error stops good releases on bad luck, which is why the lab's rule compares rates once there
  are enough answers to compare.

Rare bugs are the ones a canary is least likely to catch, and the ones that most often reach
everybody. Lesson 11 builds a fast way back for exactly those.
