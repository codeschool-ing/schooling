---
title: An instant, and what it is called where you are
version: 1
---

**`java.time` separates two questions that older code mixed up: when something happened, and what the
calendar and the clock on the wall said there at that moment.** An `Instant` answers the first: a point on
one time line, counted in seconds from the start of 1970 in UTC, the same everywhere on Earth. A
`ZonedDateTime` answers the second, and so does the `LocalDate` taken from it:

```java
// Moment.java: one instant, seen from three time zones
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;

public class Moment {
    public static void main(String[] args) {
        Instant launch = Instant.parse("2026-03-08T02:30:00Z");
        System.out.println("instant:   " + launch);
        System.out.println("epoch s:   " + launch.getEpochSecond());

        for (String zone : new String[] {"America/Sao_Paulo", "America/New_York", "Asia/Tokyo"}) {
            ZonedDateTime there = launch.atZone(ZoneId.of(zone));
            LocalDate day = there.toLocalDate();
            System.out.printf("%-18s %s  date %s, %s%n", zone, there.toLocalDateTime(), day, day.getDayOfWeek());
        }
    }
}
```

```
ana@vm:~/fp/time$ java Moment.java
instant:   2026-03-08T02:30:00Z
epoch s:   1772937000
America/Sao_Paulo  2026-03-07T23:30  date 2026-03-07, SATURDAY
America/New_York   2026-03-07T21:30  date 2026-03-07, SATURDAY
Asia/Tokyo         2026-03-08T11:30  date 2026-03-08, SUNDAY
```

## One moment, two dates

The rocket left once, at second 1,772,937,000. **In São Paulo and New York it was still Saturday the 7th;
in Tokyo it was already Sunday the 8th.** Nothing in the instant is wrong for any of them, and nothing in
it says which date is the right one, because no date is: a date only exists once a time zone is chosen.

| type | holds | an example |
|---|---|---|
| `Instant` | a point on the time line, in UTC | `2026-03-08T02:30:00Z` |
| `LocalDate` | a date with no time and no zone | `2026-03-07` |
| `LocalDateTime` | a date and a time, with no zone | `2026-03-07T23:30` |
| `ZonedDateTime` | a date and a time in a named zone | `2026-03-07T23:30-03:00[America/Sao_Paulo]` |

**Store and compare instants; show local dates.** A log line, a payment, a row's creation time are
instants, and two of them compare correctly wherever they were recorded. A birthday, a holiday or the day
a loan is due is a `LocalDate`, because it is the same day whatever time zone the reader is in. A
`LocalDateTime` with no zone is the one to be careful with: it names a time on some wall, without saying
which wall, so it cannot be turned into an instant until a zone is added.

A zone is a name like `America/Sao_Paulo`, not an offset like `-03:00`, because the offset is a rule that
changes: Brazil stopped moving its clocks in 2019, and New York moves them twice a year. The JDK carries
the history of those rules, and `atZone` used the one in force at that instant.

Every one of these classes is **immutable**: `plusDays` returns a new object and leaves the old one as it
was. That is why a `LocalDate` can be shared between threads with none of the care of lessons 11 to
15: an immutable object is safely published, as lesson 12 section 05 showed. The old `java.util.Date` and
`SimpleDateFormat` were mutable, and a `SimpleDateFormat` shared between threads can give wrong dates.
