---
title: Fowler's quadrant
version: 1
---

Asking "is this debt good or bad?" gets an argument and no answer. Martin Fowler, in a short essay
in 2009, split the question in two and drew the answers as a square. **Was the debt taken on
deliberately, or without the team realising? And was it prudent, or reckless?** Two questions with
two answers each give four kinds of debt, and each kind calls for a different response.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 390\" role=\"img\" aria-label=\"A two-by-two square. Columns: deliberate and inadvertent. Rows: reckless and prudent. Reckless and deliberate: we don't have time for design; Coreto's flaky end-to-end suite. Reckless and inadvertent: what's layering; Coreto's old reporting replica. Prudent and deliberate: we must ship now and deal with consequences; Coreto's hand-rolled PDF ticket generator. Prudent and inadvertent: now we know how we should have done it; Coreto's seat-hold locking. Below: how the debt was taken on, not how much it costs.\"><text x=\"257.5\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Deliberate</text><text x=\"562.5\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Inadvertent</text><text x=\"70\" y=\"130.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\" transform=\"rotate(-90 70 130.0)\">Reckless</text><text x=\"70\" y=\"280.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\" transform=\"rotate(-90 70 280.0)\">Prudent</text><rect x=\"110\" y=\"60\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"257.5\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“We don’t have time</text><text x=\"257.5\" y=\"114\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">for design.”</text><path d=\"M150 136 L365 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"257.5\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Coreto: the flaky</text><text x=\"257.5\" y=\"177\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">end-to-end suite</text><rect x=\"415\" y=\"60\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"562.5\" y=\"96\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“What’s layering?”</text><path d=\"M455 136 L670 136\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"562.5\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">Coreto: the old</text><text x=\"562.5\" y=\"177\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">reporting replica</text><rect x=\"110\" y=\"210\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"257.5\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“We must ship now and</text><text x=\"257.5\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">deal with consequences.”</text><path d=\"M150 286 L365 286\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"257.5\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">Coreto: the hand-rolled</text><text x=\"257.5\" y=\"327\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">PDF ticket generator</text><rect x=\"415\" y=\"210\" width=\"295\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"562.5\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">“Now we know how we</text><text x=\"562.5\" y=\"264\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">should have done it.”</text><path d=\"M455 286 L670 286\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"562.5\" y=\"310\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">Coreto: the seat-hold</text><text x=\"562.5\" y=\"327\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">locking</text><text x=\"410\" y=\"378\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">how the debt was taken on, not how much it costs</text></svg>", "caption": "Fowler's technical debt quadrant, with Coreto's four debts placed in it. The two reckless boxes are the ones a team can stop producing; the prudent, inadvertent box is the price of learning."}
```

The phrase in each box is Fowler's, and it is the sentence you would have heard in the room when
that kind of debt was taken on:

| | deliberate | inadvertent |
|---|---|---|
| reckless | "We don't have time for design." | "What's layering?" |
| prudent | "We must ship now and deal with consequences." | "Now we know how we should have done it." |

The quadrant classifies **how a debt came to exist**. It says nothing about how much the debt
costs, which is lesson 5's subject, and a debt in any box can be cheap or ruinous.

## Coreto's four, one in each box

Davi took the four debts from the register and asked the people who had been there how each one
started.

**The seat-hold locking: prudent and inadvertent.** In Coreto's first years its customers were
small theatres, and holding a seat by locking its row in the database was the simple, correct
design for that load. Nobody on that team could have known what an on-sale for a sold-out festival
would need, because no such on-sale had happened yet. "Now we know how we should have done it" is
exactly what the incident reviews say today. Fowler's point about this box is the one that matters
most: **even an excellent team produces this kind of debt**, because understanding arrives after
the code does. It is the cost of learning, and no process removes it.

What turned a modest design gap into the company's first problem was not how it started. It was
nine years of every team building features on top of it with no owner. That is interest growing,
and lesson 5 measures how fast.

**The PDF ticket generator: prudent and deliberate.** Before Coreto's first festival season, the
library it used could not print the ticket layouts festivals asked for. The team wrote its own
generator in a hurry, knowing it was a shortcut, and noted in the ticket that it should be replaced
with a maintained library after the season. That was a sound loan: the season paid for it many
times over. **The failure came afterwards.** The season ended, the next priority arrived, and the
note stayed in a closed ticket. It is the case Cunningham warned about — a prudent loan never repaid.

**The flaky end-to-end suite: reckless and deliberate.** The suite was written against shared
staging data, with fixed waits instead of checks for the page being ready. When tests began failing
at random, the team knew why, and added automatic retries instead of fixing the tests, because
there was "no time this sprint". That repeated, sprint after sprint. Everybody involved knew how to write a
reliable test; the choice was made, again and again, not to.

**The reporting replica: reckless and inadvertent.** In the company's early days the Data team
built its reports by querying a read replica of the production database directly, joining the
monolith's own tables. Nobody on the team had built a separate store for analytics before, and
nobody asked somebody who had. Now every change to a table in `coreto-core` risks breaking a report
that somebody in finance relies on. "What's layering?" is unkind, and it is also accurate: the team
did not know there was a decision to make.

## What each box calls for

Classifying the debt is useful only because it changes what you do next. **Paying the debt deals
with the past; the box tells you what to change so that less of the bad kind is taken on in
future.**

| box | what it calls for | at Coreto |
|---|---|---|
| prudent, inadvertent | accept it as the cost of learning, and plan time to rework designs as understanding grows | review the hold design after each big on-sale, now that there is a load test |
| prudent, deliberate | write the loan down with a trigger for repayment, and honour it | a register line with a date, read at each quarterly review |
| reckless, deliberate | change the rule that made the shortcut cheap | a test that needed a retry to pass counts as failed |
| reckless, inadvertent | bring in the knowledge that was missing: review, pairing, hiring | Data's next store designed with a reviewer from Platform |

The two reckless boxes deserve the most attention, because they are the ones a team can stop
producing. Deliberate recklessness is usually a response to pressure that nobody pushed back on:
lesson 13 of the `architect-communication` course is about negotiating deadline, scope, quality and
debt so that the shortcut is a decision somebody signs rather than a habit. Inadvertent recklessness
is a gap in knowledge, and the remedy is the knowledge, not a rule.

## The quadrant judges decisions, not people

The same code can sit in different boxes depending on who tells the story. The engineer who wrote
the PDF generator remembers a prudent loan with a plan; the engineer who inherited it, with no plan
in sight, sees recklessness. Both are describing something real.

So classify with the people who were there, write down what they say, and treat the box as a fact
about **the decision and its circumstances**. A register that reads as a list of culprits stops
getting honest answers the first time somebody is blamed in it, and then the quadrant has nothing
true left to classify.
