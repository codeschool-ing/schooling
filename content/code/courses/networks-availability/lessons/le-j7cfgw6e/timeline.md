---
title: Times, and the zone they are in
version: 1
---

The timeline is the spine of a record: what happened, in order, with the time each thing was seen. It is
how cause is told from coincidence, as in "the downloads stopped a few minutes after the firewall change
was pushed", and how your notes are lined up with logs from machines you do not run. The moments worth a
line are the first symptom, the first report, the start of the diagnosis, the cause found, the fix
applied and the fix verified, because **the gaps between them are what lesson 17's promises are measured
against**: time to notice, time to restore.

Lesson 21's transcripts carry no clock time at all. Each command and its output is there, and their order
is known, but not when any of them ran, and nothing can recover that now. **That is the first rule of a
timeline: the time is written when the thing is seen**, because afterwards it is gone. In a terminal that
means a prompt that shows the time, or `date` run before a command that matters; in notes it means the
clock before the sentence. Neither was done in lesson 21's lab, which is why its write-up has an order and
no times.

When times are written, their zone decides whether they can be compared. The one clock time these
lessons printed is in lesson 22, where mtr opened each report with a line like `Start:
2026-09-28T18:17:16-0300`. **The `-0300` is the offset from UTC**, and it is there because the lab's
clock runs on `America/Sao_Paulo`. A ticketing system in UTC, a provider's support desk in another
country and a cloud console in a zone of its own will each write the same instant differently. A few
lines of Python show what the offset buys, using the two mtr start lines:

```schooling-example
{"language": "python", "file": "when.py", "parts": [{"code": "from datetime import datetime, timezone"}, {"code": "# The two Start lines of the mtr reports in lesson 22, as printed.\nfirst = datetime.strptime(\"2026-09-28T18:17:16-0300\", \"%Y-%m-%dT%H:%M:%S%z\")\nsecond = datetime.strptime(\"2026-09-28T18:17:40-0300\", \"%Y-%m-%dT%H:%M:%S%z\")", "note": "Both start lines exactly as mtr printed them in lesson 22, read with a format that keeps the `-0300`. What comes out is an instant, not a clock reading."}, {"code": "print(\"local:\", first.isoformat())\nprint(\"UTC:  \", first.astimezone(timezone.utc).isoformat())\nprint(\"apart:\", second - first)", "note": "The same instant written in the lab's zone and in UTC, and the gap between the two reports. Subtracting two instants that carry offsets is correct whatever zone each was written in."}, {"code": "# The same clock reading with its offset thrown away, then taken for UTC.\nnaive = datetime.strptime(\"2026-09-28 18:17:16\", \"%Y-%m-%d %H:%M:%S\")\nwrong = naive.replace(tzinfo=timezone.utc)\nprint(\"off by:\", first - wrong)", "note": "The mistake this section is about: the clock reading kept, its offset thrown away, and the result assumed to be UTC, as happens when a log line is pasted into a ticket."}], "output": "local: 2026-09-28T18:17:16-03:00\nUTC:   2026-09-28T21:17:16+00:00\napart: 0:00:24\noff by: 3:00:00"}
```

The two reports started 24 seconds apart, and that difference is the same in every zone. The same
reading with its offset thrown away and taken for UTC is **three hours wrong**, and three hours is enough
to put an effect before its cause in a timeline built from two sources.

So a record's timeline follows four rules:

1. Every time carries its offset, `2026-09-28T18:17:16-03:00`, or is in UTC and says so with a `Z` or
   `+00:00`.
2. The timeline picks one zone, usually UTC, converts everything into it, and says which in its heading.
3. A place is recorded by zone name and an instant by offset. São Paulo had summer time until 2019, so
   "São Paulo time" in an old record does not give you the offset without the date; the offset in the
   timestamp does.
4. The clocks are synchronised, by NTP, before anybody needs them. Two machines a few seconds apart
   misorder every event that happened within those seconds, and no amount of care afterwards fixes it.
