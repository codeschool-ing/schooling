---
title: Availability is a number
version: 1
---

People describe a system as reliable, or say it is always up, and neither can be checked. **Availability
is a fraction: the time a service was usable, divided by the time it was supposed to be.** A shop that
was down for 8 hours and 46 minutes last year was available for 99.9% of it, and that number can be
compared with a promise, with a competitor, or with the year before.

The fraction is quoted in nines, and the common mistake is to read them as nearly the same thing. 99%
sounds almost perfect. It allows more than three and a half days of downtime a year. Each nine added
divides the allowance by ten, so the step from three nines to four is a step from most of a working day
to under an hour. Nothing in the lab fails in this lesson, so there is no capture here: the numbers are
arithmetic, worked by small programs that were run, and the failures it cites were measured in lessons 15
and 16. This one works out the nines for a year of 365 days, a twelfth of that year, and a day:

```schooling-example
{"language": "python", "file": "nines.py", "parts": [{"code": "YEAR = 365 * 24 * 60 * 60  # seconds in a year that is not a leap year", "note": "A year of 365 days, in seconds. Everything is worked in seconds and converted only when it is printed."}, {"code": "for nines in (2, 3, 4, 5):\n    up = 1 - 10 ** -nines  # 0.99, 0.999, 0.9999, 0.99999\n    down = YEAR * (1 - up)  # the seconds the rest of the year is allowed", "note": "Two nines is 1 − 10⁻², which is 0.99. Each nine added divides what is left over by ten, and `down` is that leftover share of the year."}, {"code": "    print(f\"{up * 100:>7g}%  \"\n          f\"{down / 3600:6.2f} h = {down / 60:7.1f} min a year  \"\n          f\"{down / 60 / 12:6.2f} min a month  \"\n          f\"{down / 365:6.2f} s a day\")", "note": "The same allowance three ways: hours and minutes in a year, minutes in a twelfth of the year, and seconds in a day."}], "output": "     99%   87.60 h =  5256.0 min a year  438.00 min a month  864.00 s a day\n   99.9%    8.76 h =   525.6 min a year   43.80 min a month   86.40 s a day\n  99.99%    0.88 h =    52.6 min a year    4.38 min a month    8.64 s a day\n 99.999%    0.09 h =     5.3 min a year    0.44 min a month    0.86 s a day"}
```

Read the rows as budgets, not as grades. **At four nines the whole year's allowance is 52.6 minutes**,
which is one badly timed upgrade. At five nines it is 5.3 minutes, 0.86 of a second a day, and the time
it takes a person to see an alarm and open a laptop has spent it several times over. Five nines is
never reached by people responding quickly. It is reached by machines that take over from each other
with nobody involved, which is what lessons 15 and 16 build.

Two details decide what a number like this means, and lesson 17 gives each its own section. The first
is what counts as down: a site that answers after thirty seconds is up to a monitoring ping and down to a
customer. The second is the window. A monthly allowance of 43.80 minutes cannot be saved up and spent in
one long afternoon the month after.

## Failing less, or coming back sooner

Two more numbers travel with availability. **MTBF**, mean time between failures, is how long a thing
runs before it breaks. **MTTR**, mean time to repair, is how long it then stays broken. Availability is
MTBF divided by MTBF plus MTTR, and the formula shows that there are exactly two ways to raise it: fail
less often, or come back faster.

A server that fails once a year and takes a technician nine hours to replace is at about 99.9%. Give it a
twin that takes over in three seconds and the server fails exactly as often as before, since its MTBF
has not moved. What changed is the repair time as the customer sees it, which went from nine hours to
three seconds, while the broken server is still waiting for its technician.

**Redundancy does not make anything fail less. It makes each failure shorter**, and everything in this
lesson and the two after it rests on that sentence. It also explains why redundancy is worth nothing if
the takeover is slow: a twin that needs somebody to log in and start it has the technician's repair time,
not the machine's.
