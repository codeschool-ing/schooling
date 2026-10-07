---
title: A bad record, or a bad batch
version: 1
---

Quarantining a record is the right answer when the record is the problem. When the **batch** is the
problem — an export that went wrong at the publisher, a file cut off halfway — quarantining the bad
records and loading the rest is the wrong answer, because what is left is not a smaller version of
the truth. It is a different, false picture: a hundred books whose prices did not change, loaded as
if they were the night's complete list.

To see the difference, Ana makes a batch that is broken on purpose: two hundred records, the first
hundred with their prices removed.

```
ana@vm:~/etl$ sed 's/"list_price_cents": \("[0-9]*"\|[0-9][0-9]*\)/"list_price_cents": null/' landing/prices.jsonl | head -100 > /tmp/half_broken.jsonl; tail -100 landing/prices.jsonl >> /tmp/half_broken.jsonl
ana@vm:~/etl$ python validate_prices.py /tmp/half_broken.jsonl /tmp/out.jsonl /tmp/bad.jsonl; echo "exit status $?"; ls /tmp/out.jsonl
200 records: 99 accepted, 101 rejected
  fixed       12  currency in lower case
  fixed       20  isbn written with hyphens
  fixed        6  price sent as text
  fixed       10  publisher with stray spaces
  rejected   101  price missing
STOP: 50% rejected is more than 5%; nothing loaded
exit status 1
ls: cannot access '/tmp/out.jsonl': No such file or directory
```

A hundred and one rejected — the hundred she broke and one that arrived without a price anyway —
fifty per cent, and the validator stopped: nothing written for the loader, exit status 1. The fixes
were still counted and the quarantine still written, so the reason is on disk; but the load that
would have followed does not run, because the shell, `make` or Airflow sees the failure.

The threshold of 5% is a judgement, like lesson 10's timeout. It should sit comfortably above what a
normal night produces — four in a thousand here — and well below anything that could only be an
accident. **A rule about records with no rule about the batch** lets a broken export through one
plausible record at a time.
