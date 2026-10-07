---
title: When, and how, to escalate
version: 1
---

**Escalate when the people in the disagreement do not have the authority to settle it, or when
waiting costs more than deciding; and escalate together, never as an ambush.** Escalation is not a
failure of mediation. It is the right move when the question is above the room, and the wrong one
when it is used to win.

## When it is time

Three situations justify taking a disagreement up:

1. **Neither side owns the decision.** If checkout and logistics disagree about whether Black Friday
   or route quality matters more in November, no tech lead can decide that; it is a business
   priority.
2. **The cost of not deciding is growing.** A disagreement that blocks a release, or keeps two
   teams building incompatible things, gets more expensive every day.
3. **Mediation has been tried and has stalled**, with interests and criteria on the table and still
   no agreement.

And one situation where it is never the answer: **to avoid a conversation you could have had.**
Going to the head of engineering about a colleague before talking to the colleague is not
escalation; it is a complaint, and it damages the relationship more than the original disagreement.

## The path

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Three steps left to right. The two people talk directly, not in a thread; most disagreements end here. The two owners meet with a mediator, working through interests and criteria. Whoever owns both decides, from one page written together.\"><defs><marker id=\"escpath-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the two people</text><text x=\"120\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">talk directly, not in a thread</text><path d=\"M222 85 L256 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#escpath-ah)\"></path><rect x=\"260\" y=\"50\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the two owners</text><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">with a mediator: interests, criteria</text><path d=\"M462 85 L496 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#escpath-ah)\"></path><rect x=\"500\" y=\"50\" width=\"200\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">whoever owns both</text><text x=\"600\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one page, written together</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">most disagreements end here</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each step only after the one below has been tried; never straight to the top</text></svg>", "caption": "The escalation path. The page at the last step carries the facts both sides agree on, so the person deciding hears one account of them."}
```

Each step up is only taken when the one below has been tried. Most disagreements end at the first
or second step. The ones that reach the third arrive with a document, which is the next point.

## Escalate together, with one page

When Bruna and Henrique could not agree about November priorities, they did not each go to the head
of engineering separately with their own story. Lívia asked them to write one page together:

> **The question.** In November, should logistics' release freeze match checkout's, from the 16th,
> or start on the 23rd so the new depot routes ship first?
>
> **Facts we agree on.** Black Friday is on the 27th. The depot routes save about 40 minutes of
> driver time per route. A logistics release broke checkout once this year, on 6 March.
>
> **Bruna's view.** Freeze from the 16th: one more release window is one more chance of a March.
>
> **Henrique's view.** Freeze from the 23rd: the depot opens on the 21st and drivers need the routes.
>
> **What we need from you.** A decision by Friday.

**The agreed facts are the most important part.** Writing them together forces the two sides to
separate what they disagree about from what they do not, and it means the person deciding hears one
account of the facts rather than two. The head of engineering decided in ten minutes: freeze from
the 23rd, with a load test of the depot release on the 19th. Neither side got exactly its position;
both had been heard, in their own words, in the same document.

## After the decision

The side that did not get its way commits, as lesson 8 described. The mediator posts the outcome
where the conflict started, in this case the platform channel, so that the sixty-message thread ends
with a decision rather than trailing off.
