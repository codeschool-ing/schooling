---
title: Positions and interests
version: 1
---

**A position is what somebody says they want; an interest is why they want it.** Two positions can
be impossible to reconcile while the interests behind them fit together easily, and finding that fit
is most of what mediation is. The distinction comes from Roger Fisher and William Ury's *Getting to
Yes*, written out of the Harvard Negotiation Project in 1981, and it applies to an argument about
database connections as well as to a contract.

## Under the two positions

Bruna's position was "cut logistics to 20 connections". Henrique's was "logistics needs 40". Stated
that way, one of them has to lose. In the call, Lívia asked each of them the same question, and it
was lesson 6's question in a new setting: **"What happens if you don't get that number?"**

- **Bruna:** "On a Friday evening, if logistics is using its 40, checkout can run out. I need checkout
  never to wait for a connection between 18:00 and 21:00." Her interest is **checkout's peak**.
- **Henrique:** "The route planner runs its big batch at 05:00. With 20 connections it finishes after
  06:00, and drivers are waiting at the depot with no routes." His interest is **routes ready by
  06:00**.

Two interests, at two different times of day. Nobody needed 40 connections at 19:00 on a Friday, and
nobody needed checkout's connections at 05:00.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A chart of logistics&#x27; database connections over 24 hours. The old fixed quota is a flat line at 40 all day. The new scheduled quota is 40 from 02:00 to 06:00, during the route batch, and 15 at all other times, including the checkout peak from 18:00 to 21:00.\"><defs><marker id=\"quotas-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 190 L680 190\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"60.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00:00</text><text x=\"215.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">06:00</text><text x=\"370.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12:00</text><text x=\"525.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24:00</text><text x=\"52\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"52\" y=\"126.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"52\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><polygon points=\"525.0,30 602.5,30 602.5,190 525.0,190\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></polygon><text x=\"563.75\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">checkout peak</text><polygon points=\"111.66666666666666,30 215.0,30 215.0,190 111.66666666666666,190\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></polygon><text x=\"163.33333333333331\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">route batch</text><path d=\"M60 62.0 L680 62.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></path><text x=\"266.66666666666663\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fixed quota: 40 all day</text><path d=\"M60 142.0 L111.66666666666666 142.0 L111.66666666666666 62.0 L215.0 62.0 L215.0 142.0 L680 142.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"266.66666666666663\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">scheduled quota: 40 from 02:00 to 06:00, 15 otherwise</text><text x=\"60\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">logistics' connections to the orders database, by hour of the day</text></svg>", "caption": "The two positions were 20 and 40. The two interests sat at different hours, which is why a quota that changes with the clock satisfied both."}
```

## Options for mutual gain

With the interests on the table, the option nobody had proposed was obvious: **a quota that changes
with the time of day**. Logistics keeps 40 connections between 02:00 and 06:00, when checkout is
nearly idle, and drops to 15 between 06:00 and 02:00. Checkout gains headroom at peak, logistics
keeps its batch window. The platform team confirmed it could set the quota by schedule in a day.

Fisher and Ury's four principles are worth having in mind during any such conversation:

1. **Separate the people from the problem.** The argument is about connections, not about whether
   checkout "blames everybody".
2. **Focus on interests, not positions.** The question above.
3. **Invent options for mutual gain** before deciding. The time-based quota was option three of five
   written on the whiteboard; the first two were the positions.
4. **Insist on objective criteria.** The next section.

## The relationship conflict does not disappear

Paulo's line about blame was still in the thread. Lívia did not ask anybody to apologise in public,
which would have reopened it. After the call she spoke to Paulo alone: "That line about checkout
landed badly. What was behind it?" It turned out logistics had been blamed in the first draft of the
6 March incident notes, before the blameless rewrite (lesson 15 is about why that matters), and
Paulo had not forgotten. **A relationship conflict usually has a history, and the history is told in
private, not in a channel.**
