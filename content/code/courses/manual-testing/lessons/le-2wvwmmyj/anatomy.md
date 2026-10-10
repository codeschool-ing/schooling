---
title: The parts of a test case
version: 1
---

A test case is often written as a reminder to the person who wrote it: *test the booking*, *check
the discount*. That is a note about what to do next, and it has no verdict in it. Two testers who
follow it do two different things, and neither can say afterwards whether it passed. **A test case
is the conditions, the inputs, the actions and the expected results needed to check one thing**,
written so that whoever runs it reaches the same verdict as whoever wrote it.

The verdict is what the parts are for. A case passes when what happened matches what it said would
happen, and fails when it does not. Everything else in the case exists so that the comparison is
fair: that it starts from the right place, uses the right values and looks at the right thing.

## The fields

Teams and tools name the fields differently, and lesson 18 shows four tools that each have their
own form. Underneath, nearly every form carries the same seven fields, and two more that are only
filled in when the case runs:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 326\" role=\"img\" data-fig=\"l02-case-anatomy\" aria-label=\"A test case drawn as a form of nine rows. Seven are written before the run: id, title, requirement, precondition, test data, steps and expected result, and of those, precondition, steps and expected result are highlighted. Two are filled in when the case runs: actual result and status.\"><rect x=\"20.0\" y=\"20.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"33.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">id</text><text x=\"180.0\" y=\"33.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">TC-BOOK-01</text><rect x=\"20.0\" y=\"50.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">title</text><text x=\"180.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what the case checks, in one line</text><rect x=\"20.0\" y=\"80.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requirement</text><text x=\"180.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R4, R5</text><rect x=\"20.0\" y=\"110.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">precondition</text><text x=\"180.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the state before step 1</text><rect x=\"20.0\" y=\"140.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">test data</text><text x=\"180.0\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the values typed and chosen</text><rect x=\"20.0\" y=\"170.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">steps</text><text x=\"180.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one action each, numbered</text><rect x=\"20.0\" y=\"200.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">expected result</text><text x=\"180.0\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worked out from the requirement</text><rect x=\"20.0\" y=\"244.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">actual result</text><text x=\"180.0\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what really happened</text><rect x=\"20.0\" y=\"274.0\" width=\"480.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32.0\" y=\"287.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">status</text><text x=\"180.0\" y=\"287.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passed, failed, blocked, not run</text><path d=\"M516.0 20.0 L524.0 20.0 L524.0 226.0 L516.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"534.0\" y=\"116.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">written before the run,</text><text x=\"534.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">with the application stopped</text><path d=\"M516.0 244.0 L524.0 244.0 L524.0 300.0 L516.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"534.0\" y=\"265.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">filled in when</text><text x=\"534.0\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the case runs</text></svg>", "caption": "The fields of a test case. The three highlighted rows carry the weight; the last two stay empty until somebody runs it."}
```

Here is one of boxoffice's cases, with every field filled in:

| field | TC-BOOK-01 |
|---|---|
| id | TC-BOOK-01 |
| title | A confirmed member booking two tickets for Hamlet pays 10% less |
| requirement | R4, R5 |
| precondition | boxoffice 1.0 is running. Hamlet has 80 seats left. The account `member@example.org` exists and is confirmed. A fresh start gives both. |
| test data | e-mail `member@example.org`; show Hamlet; 2 tickets; Student unticked |
| steps | 1. Open `http://127.0.0.1:8000/book`. 2. Type the e-mail in the E-mail field. 3. Choose Hamlet under Show. 4. Type `2` in the tickets field. 5. Press Book. |
| expected result | An order is reserved for 2 Hamlet tickets at 10% off, R$ 144,00 in total, in the state reserved. The Shows page lists 78 seats left for Hamlet. |

**The id** is the case's name for everything that refers to it, and section 06 of this lesson is
about why it is never a position in a list. **The title** says in one line what the case checks,
so somebody scanning a list of two hundred can find it. **The requirement** names the line of the
specification the case checks, which is what makes the case evidence about something the theatre
asked for.

## Precondition, step, expected result

Three fields carry the weight, and they are the three in this lesson's title.

**A precondition is what must already be true before the first step.** It describes state, not
action: which version is running, which accounts exist, how many seats a show has left. The member
account above is in the precondition because the discount depends on it. A confirmed account gets
10% off and an unconfirmed one does not, so the same five steps give two different totals depending
on something the steps never touch. A precondition is not a step in disguise either. *Start the
application* is an action; *boxoffice 1.0 is running* is the state that action produces, and it
lets the tester skip the action when the state already holds.

**A step is one action by the tester**, numbered, in the order they are taken. Open a page, type a
value, press a button. A step that hides two actions, *fill in the form and submit it*, hides the
place where the second one went wrong. Lesson 3 is about writing steps that somebody else can
follow without asking.

**An expected result is what the application should do, worked out from the requirement before
the case is run.** For TC-BOOK-01 it comes from two lines. R4 says a member can book 1 to 6 tickets,
so two tickets give a reserved order. R5 says a ticket costs the show's price and a member gets 10%
off. Hamlet costs R$ 80,00, so two tickets are R$ 160,00, and 10% off makes R$ 144,00. None of that
needed the application to be running.

Written afterwards, an expected result copies whatever the screen said, and a case that expects
what happened can never fail. **That is why the expected result is written first, from the
requirement, and the screen is only consulted when the case runs.**

## What the case leaves out

TC-BOOK-01 says nothing about the colour of the Book button, the order number, or whether the page
loads quickly. None of those is what this case checks. A case that checks one thing gives a verdict
that means one thing: when TC-BOOK-01 fails, somebody knows to look at booking and the member
discount, and nothing else. A case that also checked the layout, the e-mail and the speed would
fail for any of four reasons, and its verdict would start a conversation instead of ending one.

The order number is left out for another reason, which lesson 3 section 04 takes up: it depends on
how many orders were made before the case started.

## Filled in at the run

**The actual result** is what really happened, written down when it differs from the expected one
and kept as evidence when it matters, a screenshot or a transcript. **The status** is the verdict:
passed, failed, blocked or not run. Section 05 of this lesson runs the first cases and fills both
in.
