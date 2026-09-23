---
title: The daily stand-up
version: 1
---

The **daily stand-up**, or just *the daily*, is fifteen minutes at the same time every day, with the whole
team. People used to stand so that nobody would get comfortable and let it run long, which is where the name
comes from. Many teams now hold it on a call, sitting down, and the fifteen minutes still apply.

## What it is for

**Coordination, not reporting.** The daily answers one question for the team: *is anything in the way of
finishing what we started?* It is how Bruno's blocked #36 gets noticed on the day it gets blocked rather than
at the end of the sprint, and how Ana finds out that Carla already knows the payment provider's API.

It is not a status report to a manager. If everybody is looking at one person while they speak, and that
person is not on the team, the meeting has turned into one.

## Two ways to run it

The classic format is three questions each: *what did I do yesterday, what will I do today, is anything
blocking me?* It works, and it has a weakness: it goes person by person, so the conversation is about who is
busy rather than what is stuck.

The alternative is to **walk the board**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The board’s four columns, to do, in progress, in review and done, with an arrow running from right to left across them. The stand-up starts at in review, asking who can review it today; moves to in progress, asking what is in the way; and ends at to do, asking who is free to pull the next one. Done is not discussed.\"><defs><marker id=\"wk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">walking the board, right to left</text><path d=\"M640 50 L60 50\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#wk-ah)\"></path><text x=\"520\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">start here</text><rect x=\"20\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">to do</text><rect x=\"28\" y=\"110\" width=\"149\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"38\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">who is free to pull</text><text x=\"38\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the next one?</text><text x=\"102.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper-dim)\">3</text><rect x=\"198\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">in progress</text><rect x=\"206\" y=\"110\" width=\"149\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what is in</text><text x=\"216\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the way?</text><text x=\"280.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper-dim)\">2</text><rect x=\"376\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">in review</text><rect x=\"384\" y=\"110\" width=\"149\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">who can review</text><text x=\"394\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">it today?</text><text x=\"458.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">1</text><rect x=\"554\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 4\"></rect><text x=\"564\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">done</text></svg>", "caption": "Starting nearest to done puts the team’s attention on finishing, which is what the WIP limits of lesson 15 were asking for."}
```

Start at the column nearest *done* and ask what each card needs to move right. A card in review asks for a
reviewer; a card in progress asks what is in the way; only then does anybody talk about starting something
new. Nobody gives an account of their day, and cards nobody mentions stand out.

## A useful update, and one that is not

> Yesterday I worked on the allergens. Today I'll keep working on the allergens.

> #34 is in review and needs somebody today. I'm stuck on #35: we still don't know which payment company.
> Carla, can we talk after this?

The first one is true and tells the team nothing. The second one names cards, asks for something, and moves
a conversation out of the meeting.

## Keeping it to fifteen minutes

**Problems are named in the daily and solved after it.** When two people start discussing how to fix
something, the useful thing is to say *"let's take that after"*, and the two who need to stay, stay. Teams
often call this the *parking lot*. A daily that routinely runs to thirty minutes is costing four people an
hour a week each, and it is usually because it is solving problems in front of people who are not involved.
