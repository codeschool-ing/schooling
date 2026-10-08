---
title: The clock
version: 1
---

The RCIS gives the controller **three business days** to communicate, both to the ANPD and to the people concerned,
counted from when it **knew** the incident affected personal data. The communication may be **complemented within
twenty business days** of being sent, so the first one carries what is known and says what is still being
established. A **small processing agent**, as defined by the ANPD's Resolution CD/ANPD nº 2 of 2022, gets **double**
the time; whether a company qualifies is a question for the lawyer, and the safe plan does not rely on it.

When did the company know? Lesson 12's record answers that, and it is why the record has a time on it: the incident
was declared at 09:12 on **Thursday 17 September**, and the 09:30 message already said personal data was possible.
The DPO takes that day as the start.

Business days skip weekends and holidays, and a calendar count is easy to get wrong under pressure. A short program
does it. Write this as `prazo.py`:

```schooling-example
{"language": "python", "file": "prazo.py", "parts": [{"code": "# prazo.py START N: the date N business days after START, skipping weekends and the holidays listed\nimport datetime as dt\nimport sys"}, {"code": "\nHOLIDAYS = {  # national holidays from September 2026; add the state's and the city's before relying on it\n    dt.date(2026, 9, 7), dt.date(2026, 10, 12), dt.date(2026, 11, 2),\n    dt.date(2026, 11, 15), dt.date(2026, 11, 20), dt.date(2026, 12, 25),\n}", "note": "Only national holidays, and only from September 2026. A deadline in São Paulo also skips the state's and the city's, and a lawyer confirms the list."}, {"code": "\n\ndef add_business_days(start, n):\n    day = start\n    while n > 0:\n        day += dt.timedelta(days=1)  # the start day itself never counts\n        if day.weekday() < 5 and day not in HOLIDAYS:\n            n -= 1\n    return day", "note": "Day by day from the start: the start day never counts, and a day counts only if it is a weekday and not a holiday."}, {"code": "\n\nstart = dt.date.fromisoformat(sys.argv[1])\nn = int(sys.argv[2])\nprint(f\"{n} business days after {start:%a %d %b %Y}: {add_business_days(start, n):%a %d %b %Y}\")"}]}
```

Then three questions: the deadline, the deadline if the company is a small agent, and the deadline for the
complement if the first communication goes on the last allowed day:

```
ana@soc:~$ python3 prazo.py 2026-09-17 3
3 business days after Thu 17 Sep 2026: Tue 22 Sep 2026
ana@soc:~$ python3 prazo.py 2026-09-17 6
6 business days after Thu 17 Sep 2026: Fri 25 Sep 2026
ana@soc:~$ python3 prazo.py 2026-09-22 20
20 business days after Tue 22 Sep 2026: Wed 21 Oct 2026
```

**Tuesday 22 September** for the communication: Friday, then the weekend, then Monday and Tuesday. Friday 25 if the
time is doubled. And **Wednesday 21 October** for the complement, a day later than a plain count of four weeks
would give, because **12 October** is a national holiday and the program skips it. That one day is exactly the
kind of mistake a hand count makes.

The holiday list is national only. A deadline is also affected by state and municipal holidays, and by how the ANPD
itself counts days, so the dates are **checked with the lawyer** before anybody relies on them. The program's job
is to make the count visible and repeatable, not to be the final word.
