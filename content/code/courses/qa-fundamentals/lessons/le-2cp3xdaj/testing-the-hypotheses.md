---
title: Putting the hypotheses against each other
version: 1
---

**An experiment is worth running when its result would change what you believe.** Running the family's
exact purchase again would only confirm what Célia already said. The useful runs are the ones where the
three remaining hypotheses predict *different* prices.

## Is it Sunday?

If Sunday were the cause, an adult at a Sunday afternoon matinée would pay the evening price too. If it
is not, they pay R$ 28,00.

```
lia@lab:~/aurora$ python tickets.py 35 no sun 15:00
R$ 28,00
lia@lab:~/aurora$ python tickets.py 8 no sun 9:30
R$ 18,00
```

R$ 28,00. **Sunday is not the cause.** One command, one hypothesis gone. The child at 9:30 confirms the
arithmetic from the counter: half of the evening price, so the child discount works and the session is
what is wrong.

## Is it the hour, or the way the hour is written?

Two hypotheses are left, and they predict different things for different times. If the shop treats any
early hour as evening, then 9:30 and 10:00 are both overcharged. If the problem is how the time is
written, then the same moment written two ways will give two prices.

```
lia@lab:~/aurora$ python tickets.py 35 no sun 9:30
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no sun 9:59
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no sun 10:00
R$ 28,00
lia@lab:~/aurora$ python tickets.py 35 no sun 09:30
R$ 28,00
```

That separates them cleanly. **10:00 is a matinée and 9:30 is not**, so it is not the hour as such. And
`9:30` and `09:30`, the same moment written with and without a leading zero, cost different amounts. The
third hypothesis survives: the time reached the price rule in a form it does not handle.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l04-refutes\" aria-label=\"A grid of three hypotheses against five runs. Runs: adult on Sunday at 15:00, R$ 28,00; child on Sunday at 9:30, R$ 18,00; adult at 9:30, R$ 36,00; adult at 10:00, R$ 28,00; adult at 09:30, R$ 28,00. Hypothesis 1, it is Sunday, is refuted by the first run. Hypothesis 2, early hours count as evening, is refuted by the 10:00 run and the 09:30 run. Hypothesis 3, the way the time is written, fits every run.\"><text x=\"256.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adult, Sun 15:00</text><text x=\"256.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 28,00</text><text x=\"348.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">child, Sun 9:30</text><text x=\"348.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 18,00</text><text x=\"440.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adult, 9:30</text><text x=\"440.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 36,00</text><text x=\"532.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adult, 10:00</text><text x=\"532.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 28,00</text><text x=\"624.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">adult, 09:30</text><text x=\"624.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R$ 28,00</text><text x=\"200.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1 · it is Sunday</text><rect x=\"213.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"256.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refuted</text><rect x=\"305.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"348.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"397.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"440.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"489.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"532.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"581.0\" y=\"67.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><text x=\"200.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2 · early hours count as evening</text><rect x=\"213.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"256.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"305.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"348.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"397.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"440.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"489.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"532.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refuted</text><rect x=\"581.0\" y=\"111.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"624.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">refuted</text><text x=\"200.0\" y=\"174.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3 · the way the time is written</text><rect x=\"213.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"256.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"305.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"348.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"397.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"440.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"489.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"532.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text><rect x=\"581.0\" y=\"155.0\" width=\"86.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"624.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fits</text></svg>", "caption": "Each run was chosen because some hypothesis predicted a different price for it. Only the third survives all five, which is what makes it worth opening the code for."}
```

## Why, now that we know where to look

Only at this point is it worth opening `tickets.py`. The line that decides the session is
`if time < "17:00":`. The time is compared as **text**, not as a time of day, and Python compares two
pieces of text the way a dictionary orders words: character by character, from the left. You can ask it
directly:

```
lia@lab:~/aurora$ python -c 'print("10:00" < "17:00")'
True
lia@lab:~/aurora$ python -c 'print("09:30" < "17:00")'
True
lia@lab:~/aurora$ python -c 'print("9:30" < "17:00")'
False
```

`"9:30" < "17:00"` is false, because the first characters are compared first and `9` comes after `1`. So
9:30 is filed after 17:00, as if it were a late session, and charged as one. `"09:30"` starts with `0`,
which comes before `1`, so it works. Every session the cinema had ever had started at 10:00 or later, and
every one of them has two digits before the colon. The defect was in the code from the first day and
nobody could see it, because **no input had ever been of the shape that reaches it**. The first morning
session was.

## What the method bought

Count the runs. Two for Sunday and the child, four for the times, three to ask Python. Nine commands,
each chosen because its result could refute something, and the defect went from *a family was overcharged
on Sunday morning* to *a time written without a leading zero is compared as text and treated as an
evening session*. That is a sentence a developer can act on in a minute, and one nobody can argue with,
because every word of it comes with a command that shows it.

The contrast is with the method most people use first: **change something, try again, repeat until the
problem goes away.** It sometimes finds the fix. It rarely finds the cause, it leaves no evidence, and a
problem that goes away without being understood has a way of coming back on the next Sunday.
