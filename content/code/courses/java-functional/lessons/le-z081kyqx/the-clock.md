---
title: Asking a Clock
version: 1
---

**`LocalDate.now()` reads the system clock, and code that reads the system clock gives a different answer
every day it runs.** A rule about due dates is then impossible to check for the day before, the day of
and the day after without waiting. The fix is the idea of lesson 4, behaviour passed in as a value: every
`now` method takes a `java.time.Clock`, and code that receives the clock as an argument can be given any
clock at all:

```java
// Loans.java: code that asks a Clock for the date can be run on any day
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;

public class Loans {
    record Loan(String title, LocalDate due) {
        boolean overdue(Clock clock) {
            return LocalDate.now(clock).isAfter(due);
        }
    }

    public static void main(String[] args) {
        Loan loan = new Loan("Dune", LocalDate.of(2026, 3, 20));
        ZoneId saoPaulo = ZoneId.of("America/Sao_Paulo");

        Clock dueDay = Clock.fixed(Instant.parse("2026-03-20T15:00:00Z"), saoPaulo);
        Clock nextDay = Clock.offset(dueDay, Duration.ofDays(1));
        Clock lateEvening = Clock.fixed(Instant.parse("2026-03-21T01:30:00Z"), saoPaulo);
        Clock sameInstantUtc = lateEvening.withZone(ZoneOffset.UTC);

        System.out.println("on the due day:        " + loan.overdue(dueDay));
        System.out.println("a day later:           " + loan.overdue(nextDay));
        System.out.println("22:30 in Sao Paulo:    " + loan.overdue(lateEvening));
        System.out.println("same instant, in UTC:  " + loan.overdue(sameInstantUtc));
        System.out.println("today, by the system:  " + LocalDate.now(Clock.systemDefaultZone()));
    }
}
```

```
ana@vm:~/fp/time$ java Loans.java
on the due day:        false
a day later:           true
22:30 in Sao Paulo:    false
same instant, in UTC:  true
today, by the system:  2026-10-22
```

## Four clocks, one rule

`overdue` does not know what day it is. It asks the clock it was given, so **the same rule was checked on
the due day, the day after and at two awkward moments**, all in one run and none of them today.
`Clock.fixed` stops time at one instant, and `Clock.offset` moves another clock by a `Duration`, which is
how a test steps through a month in a millisecond. Only the last line read the real clock, and it is the
one line whose output changes from run to run.

The middle two lines are the same instant, 01:30 UTC on 21 March, and they disagree. **In São Paulo it
was 22:30 on the 20th**, the due day, and the loan was not overdue; in UTC it was already the 21st. A
server that runs in UTC and a library in São Paulo would tell the same student two different things.
The clock carries the zone, so the code that builds the clock decides it once, for the whole program,
and everything that asks the clock agrees.

`Clock.systemDefaultZone()` uses the zone the machine is set to, and `Clock.systemUTC()` uses UTC. A
program creates one where it starts, in `main`, and passes it down, the same way lesson 16 passed an
executor; a test passes a fixed one instead. **Code that calls `now()` with no argument has decided the
clock for itself**, and the test has nowhere to give it another one.
