---
title: Error Reporting groups the same failure into one row
version: 1
---

**Error Reporting reads the error entries in Cloud Logging, recognises the ones that carry a stack trace,
and groups those whose stack traces are the same into one row.** A failure that happens four thousand times
in an hour is one group with a count, a first-seen and a last-seen time, not four thousand lines to scroll
past. It needs nothing installed: an entry with severity `ERROR` or worse and a stack trace in its message
is enough, provided the trace is inside **one** entry. **Nothing here reaches Error Reporting**, which has no
emulator. What runs is a program that writes the entries correctly, and a grouping done on your computer to
show what Error Reporting would make of them.

The program below looks up two products that do not exist, as the shop's checkout would with a stale basket.
Write it into `~/gcp/errlog.py`:

```python
# errlog.py
"""errlog.py: an exception, written as one entry Error Reporting can group.

The whole traceback goes in the entry's message, in one JSON line, with the
service's name and version beside it.
"""
import json
import traceback


def price_of(product):
    prices = {"p-001": 2490, "p-002": 1890}
    return prices[product]


def report(exc):
    entry = {
        "severity": "ERROR",
        "message": "".join(traceback.format_exception(exc)),
        "@type": "type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent",
        "serviceContext": {"service": "shop-api", "version": "a1b2c3d"},
    }
    print(json.dumps(entry))


for product in ["p-001", "p-003", "p-004"]:
    try:
        price_of(product)
    except KeyError as exc:
        report(exc)
```

```
ana@laptop:~/gcp$ python3 errlog.py | wc -l
2
ana@laptop:~/gcp$ python3 errlog.py | jq -rs '.[0].message'
Traceback (most recent call last):
  File "/home/ana/gcp/errlog.py", line 28, in <module>
    price_of(product)
  File "/home/ana/gcp/errlog.py", line 13, in price_of
    return prices[product]
           ~~~~~~^^^^^^^^^
KeyError: 'p-003'
```

Two lines for two failures: each traceback, with its line breaks, is inside one JSON string, so it arrives as
one entry. Printed with `traceback.print_exc()` instead, the first failure alone would be seven entries of
plain text with no severity, and Error Reporting would see none of them.

## Grouping, done by hand

Error Reporting groups by the stack trace: the exception's type and the frames it passed through, not the
values in the message. Grouping the two entries the same way:

```
ana@laptop:~/gcp$ python3 errlog.py | jq -r '.message | split("\n") | map(select(startswith("  File"))) | join(" > ")' | sort | uniq -c
      2   File "/home/ana/gcp/errlog.py", line 28, in <module> >   File "/home/ana/gcp/errlog.py", line 13, in price_of
ana@laptop:~/gcp$ python3 errlog.py | jq -r '.message | split("\n") | map(select(length > 0)) | last'
KeyError: 'p-003'
KeyError: 'p-004'
```

One stack, counted twice: Error Reporting would show **one group of two occurrences**, with the last line,
`KeyError: 'p-003'`, as a sample, and the other product only inside the occurrence list. That is the point of
grouping and also its limit: two different missing products are one bug, correctly; but a stack trace that
changes because the code moved one line (a new release) can start a new group for the same bug, which is why
the group shows the version from `serviceContext` that first reported it.

## What a group does

- **It notifies once, when it is new.** A group seen for the first time, or seen again after being marked
  resolved, sends a notification to the project's channels. A group that keeps occurring sends nothing more,
  however often it occurs.
- **It can be muted or resolved.** Resolved and then seen again is a regression, and reopens.
- **It links back to the entries** in Cloud Logging, and from an entry that carries a trace field (lesson 9),
  to the trace.

The one thing it is not is an alert on a rate. A group that went from three occurrences an hour to three
thousand looks the same in the list, with a bigger number. That question belongs to a log-based counter on
severity `ERROR` and an alert on it (lessons 10 and 14).
