---
title: The inputs nobody mentioned
version: 1
---

**Every requirement describes the inputs its author imagined, and every real system receives others.**
A customer types a word where a number goes, leaves a field empty, chooses a time from a list somebody
else wrote. Black-box testing has a second habit, beside combining conditions: feeding the system what
nobody said it would get.

## Inputs that make it stop

```
lia@lab:~/aurora$ python tickets.py sixty no thu 20:00
Traceback (most recent call last):
  File "/home/lia/aurora/tickets.py", line 33, in <module>
    print(brl(price(int(age), student == "yes", day, time)))
                    ^^^^^^^^
ValueError: invalid literal for int() with base 10: 'sixty'
lia@lab:~/aurora$ python tickets.py 35 no thu
Traceback (most recent call last):
  File "/home/lia/aurora/tickets.py", line 32, in <module>
    age, student, day, time = sys.argv[1:]
    ^^^^^^^^^^^^^^^^^^^^^^^
ValueError: not enough values to unpack (expected 4, got 3)
```

Two tracebacks: Python's report that the program stopped, with the line it stopped on. From the outside
these are the right outcome reached the wrong way. The program refused an age of `sixty` and a missing
time, which is correct; it did it by crashing rather than by saying what was wrong. To a customer on the
website a crash is a blank page or an error screen, and on the command line it is a message only a
programmer can read.

A crash is the easiest kind of failure to judge, because **no requirement has to mention it**. Lesson 19
calls this an implicit oracle: some outcomes are wrong whatever the rule says, and a program that falls
over on bad input is one of them.

## Inputs that make it lie

The worse failures are the quiet ones, where the program accepts something it should not and answers
anyway, with a confident price.

```
lia@lab:~/aurora$ python tickets.py -5 no thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 35 maybe thu 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no Wed 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no thu 25:00
R$ 36,00
```

Each line deserves a sentence:

- **an age of `-5`** is charged as a child, because negative five is less than twelve. Nobody is minus
  five years old; the program should have refused it;
- **`maybe` for student** is read as no. Only the exact word `yes` counts, so any typo silently removes
  the reduction;
- **`Wed` with a capital W** is not recognised as Wednesday, and the customer pays full price on the
  cheapest day of the week;
- **`25:00`** is not a time at all, and is charged as an evening session.

None of these crashed, and each one charged a price. That is what makes them more dangerous than the
tracebacks: **nothing on the screen says anything went wrong.** A crash gets reported. A wrong price for
`Wed` gets paid.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l06-time-line\" aria-label=\"Three bands over a day from 00:00 to 24:00. The rule: matinée until 17:00, evening after. tickets.py with times written with two digits for the hour, like 09:30: the same split, matinée until 17:00 and evening after. tickets.py with times written with one digit, like 9:30: midnight to 1:00 is matinée, 1:00 to 10:00 is evening, and there are no one-digit times after 10:00.\"><text x=\"210.0\" y=\"45.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the rule</text><rect x=\"220.0\" y=\"30.0\" width=\"311.7\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"375.8\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">matinée</text><rect x=\"531.7\" y=\"30.0\" width=\"128.3\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"595.8\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">evening</text><text x=\"210.0\" y=\"97.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tickets.py, time as 09:30</text><rect x=\"220.0\" y=\"82.0\" width=\"311.7\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"375.8\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">matinée</text><rect x=\"531.7\" y=\"82.0\" width=\"128.3\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"></rect><text x=\"595.8\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">evening</text><text x=\"210.0\" y=\"149.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">tickets.py, time as 9:30</text><rect x=\"220.0\" y=\"134.0\" width=\"18.3\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><rect x=\"238.3\" y=\"134.0\" width=\"165.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"320.8\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">evening</text><rect x=\"403.3\" y=\"134.0\" width=\"256.7\" height=\"30.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"531.7\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no such times</text><path d=\"M220.0 186.0 L220.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"220.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M330.0 186.0 L330.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"330.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M403.3 186.0 L403.3 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"403.3\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10:00</text><path d=\"M440.0 186.0 L440.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M531.7 186.0 L531.7 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"531.7\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17:00</text><path d=\"M660.0 186.0 L660.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><path d=\"M220.0 186.0 L660.0 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Comparing times as text agrees with the rule for every time written with two digits, and gets every hour from 1 to 9 wrong when it is written with one. A black-box tester finds the third band by asking how the time reaches the program."}
```

## Where a system's inputs come from

Whether these cases matter depends on where the inputs come from, and that is a question for the team
rather than a guess. If the website offers the day as a list of buttons that always sends `wed`, a
capital W can never arrive and `Wed` is a curiosity. If somebody at the box office types the day, it is a
defect waiting for the first person who presses shift. The 9:30 session in lesson 4 arrived exactly that
way: a person typed a time into a list, and the price rule received a shape nobody had sent it before.

So the habit is: for each input, ask **who or what produces it, and what that producer could send**.
Then test the ones that are possible. The answer for `tickets.py` was humbling. Every input reached it as
text that people had typed somewhere, and none of them was checked.

## What black box found

Count the defects this lesson and lesson 4 found from the outside, without reading the code: the
Wednesday reduction stacking on another, a session time without a leading zero, a crash on a word where
a number goes, and four kinds of input accepted and silently mispriced. Most of what a customer would ever
meet in this program was found that way.

What black box could not find is anything the program does that no input from the rule leads to. If
`tickets.py` contained a line that gave a discount on one particular date, nothing in Joana's rule would
point at that date. Finding that kind of defect needs the code, and lesson 7 opens it.
