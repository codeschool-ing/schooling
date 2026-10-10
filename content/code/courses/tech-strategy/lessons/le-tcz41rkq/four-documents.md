---
title: Four documents, four questions
version: 1
---

Most engineering organisations use four words as if they were one. The vision, the strategy, the
roadmap and the backlog all get called "the plan", and a slide titled *Technical strategy* is as
likely to show a list of quarters as a diagnosis. **The four are different documents.** Each
answers its own question, looks a different distance ahead, and changes at its own pace. Mixing
them up is how a company ends up with a strategy that changes every quarter, or a backlog nobody can
explain.

## What each one answers

| document | the question it answers | how far ahead | how often it changes |
|---|---|---|---|
| vision | where do we want to be? | several years | rarely; a rewrite is an event |
| strategy | how will we get there, given what is in the way? | about a year | when the diagnosis changes |
| roadmap | what will we do, in what order? | the next few quarters | every quarter, and when something slips |
| backlog | what is next? | the next few sprints | every sprint |

Read the table down the last two columns and a pattern shows. **The further a document looks, the
less often it should change.** A vision rewritten every quarter is a mood. A backlog that stays the
same for six months is a list of things nobody is doing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A chart with two axes. Across: how far ahead the document looks, from weeks on the left to years on the right. Up: how often it changes, from every sprint at the bottom to rarely at the top. Four boxes sit on a rising diagonal: backlog at weeks and every sprint, roadmap at quarters and every quarter, strategy at about a year and when the diagnosis changes, vision at years and rarely. A dashed amber box below the strategy marks a strategy that changes every quarter: a roadmap with a different title.\"><defs><marker id=\"fourdoc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 290 L700 290\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#fourdoc-ah)\"></path><path d=\"M80 290 L80 20\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#fourdoc-ah)\"></path><text x=\"390\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">how far ahead it looks: weeks → quarters → a year → years</text><text x=\"92\" y=\"26\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">how rarely it changes</text><rect x=\"100\" y=\"220\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"243\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Backlog</text><text x=\"170\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">every sprint</text><rect x=\"250\" y=\"160\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"183\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Roadmap</text><text x=\"320\" y=\"202\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">every quarter</text><rect x=\"400\" y=\"100\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"123\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Strategy</text><text x=\"470\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">with the diagnosis</text><rect x=\"550\" y=\"40\" width=\"140\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">Vision</text><text x=\"620\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">rarely</text><rect x=\"400\" y=\"200\" width=\"290\" height=\"54\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"545\" y=\"223\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a strategy that changes every quarter</text><text x=\"545\" y=\"241\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">is a roadmap with another title</text></svg>", "caption": "The four documents on two axes. The further ahead a document looks, the more rarely it should change; a document that sits off the diagonal is doing another document's job."}
```

## Coreto's four, one of each

When Davi finished the second draft of the strategy in lesson 1, he found that Coreto already had
three of the four documents, under the wrong names. Sorted out, they read like this.

**The vision** is one sentence Helena had been saying in all-hands meetings for a long time without
writing it down:

> A buyer at a 10:00 on-sale gets the same checkout as a buyer at three in the morning.

It names no technology and no date. It will still be true, as an aim, when every line of
`coreto-core` has been replaced, which is what makes it a vision rather than a plan.

**The strategy** is lesson 1's second draft: the diagnosis that big on-sales fail in the seat-hold
code nobody owns, the policy "protect the on-sale first", and four actions. It looks about a year
ahead, because that is roughly how long the actions take, and it changes when the diagnosis does —
when the seat holds stop failing, a different challenge becomes the critical one and the strategy
is rewritten around it.

**The roadmap** sequences the actions by quarter, beside the product work, so that Júlia's product
team and the sales team can see what engineering is doing and when. The Reservations team forms in
March; the load test comes before any change to the hold path; the work on the row locks runs
for the two quarters after that.

**The backlog** is each team's next few sprints. The Reservations team's top items in its first
sprint were things like "move the seat-hold timeout out of the code and into configuration" and
"add a dashboard of lock waits on the reservation tables". Nobody outside the team needs to read
them, and they change every two weeks.

## Who writes each one

The four also have different authors, and that matters as much as the horizon. **A vision belongs
to the leadership**, here Helena, because it is a commitment about what the company is for. The
strategy is usually drafted by somebody senior who can see across teams, as Davi was asked to, and
it is signed by the CTO. The roadmap has two authors, product and engineering, and lesson 18 is
about writing it with both pens. The backlog belongs to the team that does the work.

A document written by the wrong author drifts towards the wrong question. A roadmap drawn up by
engineering alone tends to become a list of engineering wishes in date order. A backlog written by
a director becomes a roadmap with tickets in it.

## Why the confusion costs something

Each document is a tool for a different decision. The vision settles arguments about direction
that would otherwise be reopened every quarter. The strategy settles which of two good proposals
wins. The roadmap settles what happens in which order, and it is the one other departments plan
against. The backlog settles what a team starts on Monday.

When one document tries to do another's job, the decision it was meant to settle stays open. The
commonest case by far is the roadmap standing in for the strategy, and the next section takes it
on directly.
