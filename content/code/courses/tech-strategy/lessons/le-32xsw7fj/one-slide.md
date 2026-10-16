---
title: One slide
version: 1
---

A strategy review gets one slide, because the decision fits on one. **Everything else is appendix**:
it exists to answer questions, and it is opened only when somebody asks one. The habit this replaces
is the deck that walks the room through the work in the order it was done — context, architecture,
problem, options, recommendation — and reaches the decision on the last slide, after the time and
the attention have gone.

`architect-communication` lesson 5 teaches how a slide should work: one claim, stated as a full
sentence in the title, with evidence beneath it. Take that as given. A strategy's slide is a
particular case of it, with a layout that stays the same from one review to the next: **the claim
in the title, and four boxes beneath it** — what is going on, the money, the decision wanted, and
what waits.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"The layout of Davi's one slide. A title across the top: fix the seat holds before the on-sale season, R$ 48,000 once against R$ 364,800 a year of expected loss. Four boxes beneath. What is going on: big on-sales fail in the seat-hold code, 12 a year, an 8% chance each, R$ 380,000 a failure. The money: a long bar for the expected loss of R$ 364,800 a year and a short one for the fix at R$ 48,000, 7.6 times smaller. The decision we need today: approve a Reservations team of four from 1 March, moved from Checkout and Payments, no new hires. What waits a year: the microservices migration and the new front-end framework. A footer: how we will know, and a note that expected loss is an average.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"380\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">Fix the seat holds before the on-sale season:</text><text x=\"40\" y=\"76\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">R$ 48,000 once, against R$ 364,800 a year of expected loss</text><rect x=\"40\" y=\"100\" width=\"300\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">what is going on</text><text x=\"54\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Big on-sales fail in the seat-hold code:</text><text x=\"54\" y=\"168\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">12 a year, an 8% chance each,</text><text x=\"54\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 380,000 a failure.</text><rect x=\"360\" y=\"100\" width=\"320\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"374\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the money</text><rect x=\"374\" y=\"136\" width=\"280\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"382\" y=\"152\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--ink)\">expected loss: R$ 364,800 a year</text><rect x=\"374\" y=\"172\" width=\"37\" height=\"24\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"420\" y=\"188\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the fix: R$ 48,000 once · 7.6× smaller</text><rect x=\"40\" y=\"230\" width=\"300\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"252\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the decision we need today</text><text x=\"54\" y=\"278\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Approve a Reservations team of four</text><text x=\"54\" y=\"298\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">from 1 March, moved from Checkout</text><text x=\"54\" y=\"318\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and Payments. No new hires.</text><rect x=\"360\" y=\"230\" width=\"320\" height=\"115\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"374\" y=\"252\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">what waits a year</text><text x=\"374\" y=\"278\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">The microservices migration.</text><text x=\"374\" y=\"298\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">The new front-end framework.</text><text x=\"40\" y=\"368\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">How we will know: no failed big on-sale this season, and a load test that replays an on-sale.</text><text x=\"40\" y=\"387\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Expected loss is an average over many years, not a forecast for this one.</text></svg>", "caption": "Davi's slide for the strategy review. The layout is the lesson; the words are Coreto's, and yours would be your own strategy's."}
```

## The title is the decision

Read the title on its own and the review is already summarised: what Davi wants done, by when, and
the two numbers that justify it. **If the slide were lost and only its title survived, Otávio could
still say yes or no to it.** That is the test for a strategy slide's title, and it is stricter than
"a full sentence": a sentence can be true and still not ask for anything.

Compare the title Davi first wrote, "Reservation module: current state and proposal". It names a
topic. It tells Otávio nothing he could disagree with, which, as lesson 1 put it about a list of
goals, means it has not chosen anything.

## The four boxes

What is going on is the diagnosis from lesson 1, cut to what an executive needs: where the failure
is, how often, and what one costs. It has to stay checkable, so it carries numbers rather than
adjectives.

The money is the comparison from the previous section, drawn rather than tabled. Two bars, one 7.6
times the other, need no explanation, and a reader who looks at nothing else on the slide sees the
argument. **One chart, and the one that carries the decision**; a second chart is a second claim
competing for the same glance.

The decision we need today is a verb, an owner and a date, and at Coreto it says what the decision
does not cost: the four engineers already work there. That sentence answers Otávio's first question
before he asks it, because a CFO reading "a team of four" reads "four salaries" until told otherwise.
What they cost instead is the work they stop doing, which is lesson 13's opportunity cost.

**What waits is lesson 3's list of what the strategy will not do**, and it is on the slide because
it is the half of the decision people forget they are making. Approving the team means approving
that the microservices migration and the front-end framework wait a year. Putting it in a box makes
that a choice Otávio and Helena take with their eyes open, rather than a surprise two team leads
bring to them in April.

The footer carries how the company will know the strategy is working — lesson 3 again — and the
caveat about expected loss from the previous section. Both are small, and both are there so nobody
can say later that they were not told.

## What stays off it

The architecture diagram, the queue of row locks, the list of every debt in `coreto-core`, the
sprint plans. None of it is wrong and all of it is in the appendix. The usual wrong idea about an
executive slide is that it is the technical slide simplified. **It is a different slide**, about
consequences instead of mechanisms, and simplifying the mechanism produces a slide that is too
technical for the CFO and too vague for the CTO at once.

## Testing it before the room does

Cover everything but the title and ask whether the decision is still there. Then show the whole
slide, briefly, to somebody outside engineering — at Coreto, somebody from Otávio's team — and ask
one question: what is this slide asking for? If the answer is not the decision box in their own
words, the slide is not done. It is lesson 3's repeat-back test, applied to a page with one reader
instead of a whole engineering organisation.
