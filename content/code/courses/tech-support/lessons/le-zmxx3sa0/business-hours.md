---
title: Counting in business hours
version: 1
---

Counting business hours by hand goes wrong at the edges of the day and the week. A few lines of Python
do it the same way every time:

```schooling-example
{"language": "python", "parts": [{"code": "import sys\nfrom datetime import datetime, timedelta", "note": "Only the standard library: dates, and the arguments from the command line."}, {"code": "OPEN, CLOSE = 8, 18           # the service desk's hours\nWORKDAYS = range(0, 5)        # Monday to Friday; datetime counts Monday as 0", "note": "**The calendar is the SLA's, not the clock's.** These three numbers are what the contract says the service desk works; a 24-hour service would have none of them."}, {"code": "def deadline(start, hours):\n    t, left = start, timedelta(hours=hours)\n    while left:", "note": "`t` walks forward from the moment the ticket opened, and `left` is how much of the promised time is still to be spent."}, {"code": "        if t.weekday() not in WORKDAYS or t.hour >= CLOSE:\n            t = (t + timedelta(days=1)).replace(hour=OPEN, minute=0)", "note": "Outside working days, or after closing: jump to the next morning's opening. A Saturday jumps twice, to Sunday and then to Monday."}, {"code": "        elif t.hour < OPEN:\n            t = t.replace(hour=OPEN, minute=0)", "note": "Before opening on a working day: wait until the desk opens."}, {"code": "        else:\n            step = min(left, t.replace(hour=CLOSE, minute=0) - t)\n            t, left = t + step, left - step\n    return t", "note": "Inside working hours: spend what is left, or what is left of today, whichever is less."}, {"code": "start = datetime.strptime(sys.argv[1], \"%Y-%m-%d %H:%M\")\nhours = float(sys.argv[2])\nprint(f\"{start:%a %d/%m %H:%M} + {hours:g} h -> {deadline(start, hours):%a %d/%m %H:%M}\")", "note": "The ticket's opening time and the SLA's hours come from the command line, and the answer is printed with its weekday, because the weekday is what surprises people."}]}
```

Four tickets, four answers:

```
ana@host:~$ python3 sla.py "2026-09-24 09:00" 8
Thu 24/09 09:00 + 8 h -> Thu 24/09 17:00
ana@host:~$ python3 sla.py "2026-09-25 16:30" 4
Fri 25/09 16:30 + 4 h -> Mon 28/09 10:30
ana@host:~$ python3 sla.py "2026-09-26 10:00" 1
Sat 26/09 10:00 + 1 h -> Mon 28/09 09:00
ana@host:~$ python3 sla.py "2026-09-25 17:59" 0.25
Fri 25/09 17:59 + 0.25 h -> Mon 28/09 08:14
```

- Eight hours from nine on a Thursday ends at five the same day: the easy case.
- **Four hours from half past four on a Friday ends at half past ten on Monday**: one and a half on
  Friday, two and a half on Monday. The person who opened it hears "four hours" and expects an answer
  before the weekend; saying the actual time is part of the reply, lesson 4.
- An hour from a Saturday morning starts counting on Monday at eight.
- A quarter of an hour from one minute to six spends one minute on Friday and fourteen on Monday.

What it leaves out is **holidays**, which differ by city and by year. A real SLA calendar lists them,
and a ticketing system reads that list; the script would need it too before anyone trusted its
answers in December.
