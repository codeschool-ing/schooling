---
title: Periods and durations
version: 1
---

**There are two ways to say "how long", and they disagree once a year.** A `Period` counts calendar units,
years, months and days, and a `Duration` counts seconds. On most days a day is 24 hours and the two
agree; on the day the clocks move they do not:

```schooling-example
{
  "language": "java",
  "file": "Spans.java",
  "parts": [
    {
      "code": "// Spans.java: a Period counts calendar units, a Duration counts seconds\nimport java.time.Duration;\nimport java.time.LocalDate;\nimport java.time.LocalDateTime;\nimport java.time.Period;\nimport java.time.ZoneId;\nimport java.time.ZonedDateTime;\n\npublic class Spans {\n    public static void main(String[] args) {\n        LocalDate borrowed = LocalDate.of(2026, 1, 31);\n        System.out.println(\"a month after \" + borrowed + \": \" + borrowed.plusMonths(1));\n        System.out.println(\"30 days after \" + borrowed + \": \" + borrowed.plusDays(30));\n        System.out.println(\"between: \" + Period.between(LocalDate.of(2025, 11, 20), borrowed));\n",
      "note": "A `LocalDate` has no time and no zone, so its arithmetic is calendar arithmetic. A month after 31 January is the last day of February, since there is no 31 February."
    },
    {
      "code": "\n        ZoneId newYork = ZoneId.of(\"America/New_York\");\n        ZonedDateTime evening = ZonedDateTime.of(LocalDateTime.of(2026, 3, 7, 20, 0), newYork);\n        System.out.println(\"start:        \" + evening);\n        System.out.println(\"plus 1 day:   \" + evening.plusDays(1));\n        System.out.println(\"plus 24 hours \" + evening.plus(Duration.ofHours(24)));\n        System.out.println(\"hours apart:  \" + Duration.between(evening, evening.plusDays(1)).toHours());\n",
      "note": "New York moves its clocks forward at 02:00 on 8 March 2026. Adding a day keeps the time of day; adding 24 hours keeps the length."
    },
    {
      "code": "\n        ZonedDateTime gap = ZonedDateTime.of(LocalDateTime.of(2026, 3, 8, 2, 30), newYork);\n        System.out.println(\"02:30 asked:  \" + gap);\n    }\n}\n",
      "note": "02:30 on that morning never happens in New York: the clocks jump from 01:59 to 03:00."
    }
  ]
}
```

```
ana@vm:~/fp/time$ java Spans.java
a month after 2026-01-31: 2026-02-28
30 days after 2026-01-31: 2026-03-02
between: P2M11D
start:        2026-03-07T20:00-05:00[America/New_York]
plus 1 day:   2026-03-08T20:00-04:00[America/New_York]
plus 24 hours 2026-03-08T21:00-04:00[America/New_York]
hours apart:  23
02:30 asked:  2026-03-08T03:30-04:00[America/New_York]
```

## Calendar time and elapsed time

`plusMonths(1)` on 31 January gave 28 February, **the last day of the month rather than an error or 3
March**, and `plusDays(30)` gave 2 March, which is a different answer to a question that sounds the same.
A library that lends books "for a month" has to choose which it means, and write the choice down.
`Period.between` gave `P2M11D`: two months and eleven days, in the ISO notation `P` for period.

In New York the clocks moved forward an hour during the night of 8 March. **`plusDays(1)` kept the time
of day**, 20:00 again, and so the day was only 23 hours long, as `Duration.between` said. **`plus` with
24 hours kept the length** and landed at 21:00. Neither is a bug; they answer different questions. A
reminder for the same time tomorrow wants the first, a timeout of one day wants the second.

The last line asked for 02:30 on the morning the clocks jumped, a time that never existed there. Java did
not refuse it: it moved the time forward by the length of the gap, to 03:30, and changed the offset from
`-05:00` to `-04:00`. A program that builds times from what people type can meet this, and in the autumn
the opposite, a time that happened twice.

| type | counts | example | `plus` keeps |
|---|---|---|---|
| `Period` | years, months, days | `P2M11D` | the time of day |
| `Duration` | seconds and nanoseconds | `PT24H` | the length |

`Duration` is also what lesson 17 passed to `Thread.sleep`: elapsed time, which
has nothing to do with calendars. For measuring how long code takes, `System.nanoTime` of lesson 9 is
still the right tool, since the wall clock can be corrected while it runs.
