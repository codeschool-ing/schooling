---
title: Severity and priority
version: 1
---

Most new testers treat severity and priority as one number written twice: a bad defect is fixed
first, a small one later. **They are two different questions, asked by different people.**
Severity is how much harm the defect does, and the tester can measure it from the product.
Priority is how soon it gets fixed, and that depends on things the tester often cannot see: the
release date, what else is waiting, who is about to use which page. Most of the time the two
agree. The cases where they do not are why both fields exist.

## Severity: how much harm

A scale is only useful if two testers put the same defect on the same step, so each step is
written as a test somebody can apply. This is a common four-step scale, the one lesson 1's exit
criteria used:

| severity | the test |
|---|---|
| **critical** | money or data is lost or wrongly taken, or the main path stops for everybody, and there is no way round it |
| **major** | a requirement fails in a way users meet, but there is a way round it, or only some users meet it |
| **minor** | the requirement is met in substance and the product is harder to use than it should be |
| **trivial** | cosmetic: a word, a colour, an alignment, with no effect on what anybody can do |

Run boxoffice 1.1's known defects through it. The student discount lesson 10 found is the clearest:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8000/book | grep -A1 'ticket(s)'
<p>Hamlet, 2 ticket(s), 10% off:
<strong>R$ 144,00</strong></p>
```

R5 says students pay half, so two Hamlet tickets at R$ 80,00 should cost R$ 80,00 in all. The page
charges R$ 144,00. Every student who books is charged too much, on every order, and there is
nothing they can do about it: **critical**.
Lesson 5's refund of a used order is critical too, by the same test: money goes back for a seat
somebody sat in, and the seats return to sale.

The traceback of section 02 is **major**. The booking page fails and shows the program's insides
to whoever typed the word, but a customer who types a digit books normally. The shows table that
lesson 7 found 760 pixels wide is **minor**: on a phone the customer scrolls sideways and still
books. *"An order that is used cannot be useed"*, from lesson 11, is **trivial**: a misspelt
sentence on a refusal that is itself correct.

**Severity is about the harm, not about how the defect was found or how hard it was to find.** A
defect that took two days of exploring to uncover can be trivial, and one that anybody hits in
the first minute can be critical.

## Priority: how soon

Priority is a ranking in time, usually written P1 to P3 or P4: fix before the next build, fix in
this release, fix when convenient. **It is normally set at triage, by the person who owns the
product**, with the tester and a developer in the room. Lesson 16 is that meeting. The tester may
propose a priority in the report; the field is theirs to suggest and someone else's to decide,
because the facts that move it are rarely in the tester's hands.

Here is boxoffice's list again, with the priorities the theatre's manager gives them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l15-severity-priority\" aria-label=\"A grid with severity along the bottom, trivial, minor, major and critical, and priority up the side, P3 at the bottom to P1 at the top. A, the student discount ignored, and B, a used order refunded, sit at critical and P1. C, the traceback on a word, sits at major and P2. D, the shows table 760 pixels wide, sits at minor and P1. E, cannot be useed, sits at trivial and P3.\"><rect x=\"110.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"294.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"24.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"110.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"294.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"90.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"110.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"294.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"156.0\" width=\"86.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"98.0\" y=\"47.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">P1</text><text x=\"98.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">next build</text><text x=\"98.0\" y=\"113.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">P2</text><text x=\"98.0\" y=\"128.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">this release</text><text x=\"98.0\" y=\"179.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">P3</text><text x=\"98.0\" y=\"194.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">when convenient</text><text x=\"153.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trivial</text><text x=\"245.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minor</text><text x=\"337.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">major</text><text x=\"429.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">critical</text><text x=\"291.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">severity: how much harm</text><text x=\"14.0\" y=\"12.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">priority: how soon</text><circle cx=\"413.0\" cy=\"54.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"413.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><circle cx=\"445.0\" cy=\"54.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"445.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><circle cx=\"337.0\" cy=\"120.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"337.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><circle cx=\"245.0\" cy=\"54.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"245.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D</text><circle cx=\"153.0\" cy=\"186.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><text x=\"153.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"502.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A</text><text x=\"520.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">student discount ignored</text><text x=\"502.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B</text><text x=\"520.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a used order refunded</text><text x=\"502.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C</text><text x=\"520.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">traceback on a word</text><text x=\"502.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">D</text><text x=\"520.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shows table 760 px wide</text><text x=\"502.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">E</text><text x=\"520.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">“cannot be useed”</text></svg>", "caption": "Five defects of boxoffice 1.1, rated twice. The tester measures the column; the triage decides the row. D is the one that surprises: minor, and first in line."}
```

Three of the five sit where you would guess. The other two show what priority knows that severity
does not.

**The shows table is minor and P1.** The manager says most tickets are sold from phones, and the
season's advertising, which links straight to the shows page, starts next week. Nothing about the
defect changed; the cost of leaving it did.

**The traceback is major and only P2.** It has a way round it and is met by few customers, so it
waits behind two defects that take money from everybody. Lesson 14's point still stands, and it
is the argument a tester makes at triage for moving it up: an error page that shows code is also
information handed to a stranger.

The combination the figure does not hold is the one that surprises people most: **critical and
low priority**. A crash in a feature nobody can reach yet, such as the booking page of a season not
on sale until next year, is critical by the scale and can wait, because no customer meets it
before it is fixed.

## Getting the fields right

**Do not raise severity to get attention.** A report marked critical that is plainly minor teaches
the triage to read your severities with a discount, and the next critical one you file is read the
same way. If you think something deserves to be fixed sooner, that is an argument about priority,
and the place for it is a sentence in the report saying why.

**Severity does not change after triage unless the facts do.** Priority changes all the time:
a deadline moves, a customer complains, a fix elsewhere makes this one cheap. Severity moves when
something new is learnt about the harm, for example that the traceback also appears on a page every
customer uses.
