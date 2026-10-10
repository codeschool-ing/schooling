---
title: The lifecycle of a defect
version: 1
---

A defect report is often pictured as a ticket with two states, open and closed, and a tester's
part in it as the moment it is opened. **A report goes through a handful of states, and the
tester is the person who moves it at both ends**: in at the start, by filing it, and out at the
end, by confirming the fix. In between, other people move it, and each move answers one question.
A team that agrees on the states can look at any report and know whose turn it is.

Every tracker names the states its own way, and lesson 17 shows four of them. The names below are
common ones; what matters is the questions, because those are the same everywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l16-lifecycle\" aria-label=\"A state diagram of a defect report. New leads to triaged, also called open, then in progress, then fixed. A delivered build moves fixed to ready for retest. From ready for retest, a passing retest leads to verified and then closed; a failing retest leads to reopened, which goes back to in progress. From triaged, three exits lead out of the path: duplicate, rejected and deferred. The tester moves a report into new, and out of ready for retest in either direction.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">new</text><rect x=\"190.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">triaged (open)</text><rect x=\"360.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">in progress</text><rect x=\"540.0\" y=\"40.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fixed</text><rect x=\"540.0\" y=\"140.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ready for retest</text><rect x=\"360.0\" y=\"140.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reopened</text><rect x=\"540.0\" y=\"240.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"259.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">verified</text><rect x=\"360.0\" y=\"240.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"259.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">closed</text><path d=\"M90.0 14.0 L90.0 40.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><path d=\"M160.0 59.0 L190.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M330.0 59.0 L360.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M500.0 59.0 L540.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M610.0 78.0 L610.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"618.0\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">build delivered</text><path d=\"M610.0 178.0 L610.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"618.0\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">retest passes</text><path d=\"M540.0 159.0 L500.0 159.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"520.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">retest fails</text><path d=\"M430.0 140.0 L430.0 78.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M540.0 259.0 L500.0 259.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M205.0 78.0 L205.0 247.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M205.0 137.0 L222.0 137.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"224.0\" y=\"120.0\" width=\"106.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"277.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">duplicate</text><path d=\"M205.0 192.0 L222.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"224.0\" y=\"175.0\" width=\"106.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"277.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rejected</text><path d=\"M205.0 247.0 L222.0 247.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"224.0\" y=\"230.0\" width=\"106.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"277.0\" y=\"247.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deferred</text><text x=\"20.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">exits at triage</text><path d=\"M20.0 236.0 L48.0 236.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"56.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">moved by the tester</text><path d=\"M20.0 258.0 L48.0 258.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"56.0\" y=\"258.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">moved by others</text></svg>", "caption": "The states a defect report passes through, and the moves between them. The tester's moves are drawn in a colour of their own: filing the report, and deciding the retest."}
```

## The main path

**New.** The report exists and nobody but its writer has read it. The question waiting is *is this
real, and does it matter?*, and nobody should be working on it yet.

**Triaged**, often called **open**. Somebody has read it, agreed it is a defect, confirmed or
corrected the severity, set a priority and, usually, named who will fix it. Section 03 of this
lesson is the meeting where that happens.

**In progress.** A developer has taken it. This state exists so that two people do not fix the same
defect, and so that a report nobody has touched for a month is visible as exactly that.

**Fixed.** The developer has changed the code and believes the defect is gone. Believes is the word:
the developer has tested the change, but on their own machine, against their own reading of the
report.

**Ready for retest.** A build containing the fix has reached the test environment. A fix that
exists only on the developer's machine cannot be retested, which is why this is a state of its own
and not part of *fixed*: it says the tester can start.

**Verified**, then **closed.** The tester has run the report's reproduction on the new build, seen
the expected result, and run the neighbouring checks a fix might have disturbed. Some teams close as
soon as a fix is verified; others leave it verified until the release ships and close everything
together.

boxoffice has already walked one defect the whole way. Lesson 4 found that six tickets were refused
although R4 allows 1 to 6: that was *new*. Rui changed the rule, the change went into release 1.1,
and lesson 9 checked it on the new build. That check is the retest, and on a fresh 1.1 it reads:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8000/book | grep msg
<p class="msg">Order 1001 reserved.</p>
```

Six tickets make an order, the expected result of the original report, so the defect is verified.

## The way back: reopened

When the retest fails, the report goes back, and **reopened** says so. It is the same defect, with
its history attached, and the developer sees what they tried and why it did not hold. Filing a new
report instead would lose that history and make the defect look younger than it is.

**A retest that fails is not the same as a fix that broke something else**, and the difference
decides which of the two you do. Release 1.1 also fixed lesson 5's member discount, and lesson 10's
regression run found that the same edit stopped students paying half. Lesson 5's defect, a member
booking five or more getting 25%, is fixed: on 1.1 that member gets 15%, as R5 says. The student price is
a new failure, of a different rule, introduced by the fix. So lesson 5's defect is verified and
stays closed, and the student price is a new report that names release 1.1's change as the cause.
Reopening lesson 5's defect for it would leave the record saying the member discount is still broken, which is false.

## The way out: three ends that are not a fix

Some reports leave the path at triage, and each exit is a decision with a reason written on it.

**Duplicate**: the defect is already reported. The new report is closed and linked to the old one,
and anything useful in it, a better reproduction or another environment, is copied across.

**Rejected**: it is not a defect. Most often the program does what the requirement says and the
reporter read the requirement differently; sometimes nobody can reproduce it. Section 04 of this
lesson is about both of these exits.

**Deferred**: it is a defect, and the team has decided not to fix it in this release. It stays
in the tracker with its severity, and comes back to the next triage that plans a release. Deferring
is honest in a way that letting a report sit in *new* for six months is not: the first is a
decision somebody can disagree with, the second is a decision nobody took.

## Who moves what

The figure's colours carry the rule worth remembering: **the tester moves a report into the
lifecycle and out of it, and nobody else closes a defect on the tester's behalf.** A developer who
marks their own fix *closed* has skipped the one check that does not depend on their own reading of
the report. When a team is short of people, the state that disappears first is *ready for retest*,
and the defects that come back from customers are the ones that went past it.
