---
title: It works on my machine
version: 1
---

"It works on my machine" is usually heard as a developer brushing a report away. Read literally, it
is a measurement, and a useful one: **the same build behaves differently in two places, so
something about the two places is different, and that something is part of the defect.** Both
people are telling the truth. The tester's job is to find the difference and turn it into steps
anybody can follow.

## The report

At half past five on a Saturday afternoon, São Paulo time, you are checking the 1.1 release
candidate on staging before it goes live. You sign in as the member and try to book two tickets
for The Seagull, which starts at 20:00. Booking should close one hour before the show (R4), at
19:00, so it ought to be open. The page answers:

> Booking for this show has closed.

You report it. Rui opens his laptop, starts the same 1.1 file, books two tickets for The Seagull at
the same moment and gets an order. He writes back that it works on his machine, and he is right.

## Holding everything still but one thing

Two machines differ in dozens of ways, and comparing them by hand finds nothing. The technique is
the one every experiment uses: **reproduce both results on one machine, then change one setting at
a time until the result flips.** Whatever flipped it is the cause, or close to it.

The first obstacle is the clock. The defect happens at 17:30, and you cannot wait for 17:30 every
time you want to try something. boxoffice reads the moment it should believe from `BOXOFFICE_NOW`,
so you can pin it: the same instant, written with its São Paulo offset, `-03:00`, on every run.

The second thing to hold or vary is the time zone, and on Linux and macOS a program reads it from
the variable `TZ`. Your machine is set to São Paulo, and Rui told you the rented servers are set to
UTC. So the first run copies Rui's laptop. Stop boxoffice if it is running, and start it in its
terminal like this:

```
ana@laptop:~/boxoffice$ TZ=America/Sao_Paulo BOXOFFICE_NOW=2026-10-10T17:30:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

Book two tickets for The Seagull as the member, in the browser or from the second terminal:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

Rui's result. Now press Ctrl-C and start it again with **one** thing changed, the time zone:

```
ana@laptop:~/boxoffice$ TZ=UTC BOXOFFICE_NOW=2026-10-10T17:30:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

The same booking, at the same instant:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

Your result from staging, on your own laptop. Same file, same instant, same request; the time zone
was the only change, so the time zone is in the defect. That is defect 9 of this course, and you
found it without opening the code.

**Nothing on the screen gives it away.** In the UTC run the home page lists the show exactly as it
does in São Paulo:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o '<td>The Seagull</td><td>[^<]*</td>'
<td>The Seagull</td><td>2026-10-10 20:00</td>
```

## Where it closes

A defect report says when it happens, and "at 17:30" is one point, not a rule. Lesson 4's boundary
thinking finds the rule: try a moment either side of where you suspect the edge is. Start it as
`TZ=UTC BOXOFFICE_NOW=2026-10-10T15:59:00-03:00 python3 boxoffice.py` and book:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

Then as `TZ=UTC BOXOFFICE_NOW=2026-10-10T16:01:00-03:00 python3 boxoffice.py`:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg
<p class="msg">Booking for this show has closed.</p><form method="post" action="/book">
```

**On a machine set to UTC, booking closes at 16:00 São Paulo time, three hours early.** That is a
sentence the theatre's manager can weigh: three hours of an evening's sales, every evening, on the
only machine customers use.

## The cause, in a tester's words

You do not need the line of code to explain it, and a report that guesses at code is often wrong.
What the two runs show is this. The show times are São Paulo times written with no zone, as R1
says. The program compares them with **the machine's own clock**. On a machine set to São Paulo the
two agree; on a machine set to UTC, the clock reads three hours ahead, so 17:30 in São Paulo is
20:30 on that machine, which is past the 19:00 cut-off.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l21-two-clocks\" aria-label=\"Two clock lines, one above the other, lined up so that the same instant sits at the same place. The upper line is a machine set to São Paulo time, running from 14:00 to 22:00. The lower line is a machine set to UTC, whose labels run three hours ahead, from 17:00 to 01:00. A vertical line marks one instant, 17:30 in São Paulo, which the upper machine reads as 17:30 and the lower as 20:30. Each line has the booking cut-off at 19:00 on its own clock: on the upper line that is to the right of the instant, so booking is open; on the lower line it falls at 16:00 São Paulo time, to the left of the instant, so booking is closed.\"><text x=\"60.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">machine set to São Paulo</text><rect x=\"435.0\" y=\"76.0\" width=\"225.0\" height=\"14.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><path d=\"M60.0 90.0 L660.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 86.0 L60.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14:00</text><path d=\"M135.0 86.0 L135.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"135.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M210.0 86.0 L210.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16:00</text><path d=\"M285.0 86.0 L285.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17:00</text><path d=\"M360.0 86.0 L360.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M435.0 86.0 L435.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"435.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><path d=\"M510.0 86.0 L510.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20:00</text><path d=\"M585.0 86.0 L585.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"585.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M660.0 86.0 L660.0 94.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">22:00</text><path d=\"M435.0 66.0 L435.0 96.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"441.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">closes 19:00</text><text x=\"60.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">machine set to UTC</text><rect x=\"210.0\" y=\"191.0\" width=\"450.0\" height=\"14.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><path d=\"M60.0 205.0 L660.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 201.0 L60.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"60.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17:00</text><path d=\"M135.0 201.0 L135.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"135.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><path d=\"M210.0 201.0 L210.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"210.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><path d=\"M285.0 201.0 L285.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20:00</text><path d=\"M360.0 201.0 L360.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21:00</text><path d=\"M435.0 201.0 L435.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"435.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">22:00</text><path d=\"M510.0 201.0 L510.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"510.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">23:00</text><path d=\"M585.0 201.0 L585.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"585.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M660.0 201.0 L660.0 209.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">01:00</text><path d=\"M210.0 181.0 L210.0 211.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"216.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">closes 19:00</text><path d=\"M322.5 36.0 L322.5 262.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"322.5\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">the same instant: 17:30 in São Paulo</text><circle cx=\"322.5\" cy=\"90.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"314.5\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">reads 17:30</text><text x=\"314.5\" y=\"138.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">open</text><circle cx=\"322.5\" cy=\"205.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"330.5\" y=\"239.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">reads 20:30</text><text x=\"330.5\" y=\"253.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">closed</text></svg>", "caption": "One instant on two machines. Each closes booking at 19:00 by its own clock, and the UTC machine reaches 19:00 three hours sooner."}
```

That is enough for Rui to find the line in a minute, and it is phrased so that it stays true however
he fixes it.

## On Windows

None of this was run on Windows, and the commands above do not carry over. Windows keeps its time
zone as a system setting, and Python there does not read a zone name such as `America/Sao_Paulo`
from a `TZ` variable the way it does on Linux and macOS. To reproduce the UTC run on Windows you
change the computer's own time zone to UTC in the date and time settings, start boxoffice with
`BOXOFFICE_NOW` set, and set the zone back when you are done. In PowerShell the variable is set
with `$env:BOXOFFICE_NOW = "2026-10-10T17:30:00-03:00"` before `py boxoffice.py`.

## What made it hard to find

Three things, and each is common. **The difference was invisible**: no page shows the zone, and
nobody had listed the clock as part of the environment. **It depended on the hour**: in the morning
both machines accept every booking, so most test runs pass on both. **And the two people involved
each had a true result**, which turns a defect into an argument about whose machine is right. The
way out of that argument is the pair of runs above, which anybody can repeat and which show both
results at once.
