---
title: Three types, and the one with no time zone
version: 2
---

```python
from datetime import date, datetime, timedelta

date.today()                      # 2026-09-21
datetime.now()                    # 2026-09-21 14:03:11.482000
date(2026, 9, 21) + timedelta(days=30)
```

`date` is a day. `datetime` is a day and a time. `timedelta` is a DURATION, and it is what makes
the arithmetic work: a date plus a duration is a date, and a date minus a date is a duration.

```python
(date(2026, 12, 25) - date.today()).days
```

**That is the whole reason not to do this by hand.** Thirty days from the 15th of February is a
question with a right answer that depends on the year, and nobody gets the leap rule wrong twice
— they get it wrong once, in production, in February.

## Parsing and formatting

```python
datetime.strptime("2026-09-21", "%Y-%m-%d")      # string  → datetime
datetime.now().strftime("%d/%m/%Y")              # datetime → string
date.fromisoformat("2026-09-21")                 # the ISO case, shorter
```

`strptime` PARSES and `strftime` FORMATS, and everybody looks the letters up every time. The
useful habit is different: **when the string is ISO — year, month, day, with dashes — use
`fromisoformat`**, which is shorter, faster and cannot have the format written wrongly.

And store dates as ISO. `21/09/2026` and `09/21/2026` are the same string to a computer and
different days to two people.

## The naive datetime

```python
datetime.now()                    # naive — no time zone attached
datetime.now(timezone.utc)        # aware
```

A `datetime` with no time zone is called NAIVE, and it is the default. It means "this time,
somewhere" — and comparing a naive one with an aware one raises, which is Python refusing to
guess.

**The rule that survives contact with reality: store and compute in UTC, convert at the edge.**
A timestamp in the database is UTC; the screen shows the reader's own time. Anything else is a
bug that appears twice a year and cannot be reproduced.

`zoneinfo.ZoneInfo("America/Sao_Paulo")` is the standard library's time zones, and a NAMED zone
rather than an offset — because the offset changed, historically, and the name knows when.

## What this course does not need

Time zone conversion in every direction, calendars, business days. When you get there,
`dateutil` is the dependency everybody uses and it is worth the install.
