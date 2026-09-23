---
title: The surprise at the end
version: 1
---

Ticket #38 asked for **gift cards**: a customer buys one, gives it to somebody, and they spend it at the
bakery. Ana built it over the sprint and showed it at the review. Three people were surprised, in
three different ways:

- **Marta**: gift cards were meant to be spent **in the shop only**. The owner does not want online orders
  paid with them, because the till cannot see online balances. That was said in a meeting Ana was not in.
- **Paulo**: his design showed the balance on its own screen, after the code is typed. Ana put it on the
  order page, because the ticket did not say where, and the drawing was in a folder she had never been
  sent.
- **Diego**: spending 10 on a card with 8 left takes the balance to **-2**. He found it in ten minutes, on the
  last day.

Each surprise is small. Together they send most of the sprint's work back, and nobody made a mistake that
any one of them could have seen alone.

## Why the end

Every one of those facts existed at the start of the sprint. What went wrong was **when people met**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 366\" role=\"img\" aria-label=\"Two ways a feature moves through four roles over time. Above, a relay: product works alone, hands over to design, which hands over to development, which hands over to QA; each bar starts where the previous one ends, and the surprises all land at the end. Below, together: all four bars run side by side from the start, with small loops between them marked each week, where small surprises are found.\"><defs><marker id=\"rl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a relay: each hands over and leaves</text><text x=\"20\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">product</text><rect x=\"140\" y=\"44\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">design</text><rect x=\"270\" y=\"70\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">development</text><rect x=\"400\" y=\"96\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">QA</text><rect x=\"530\" y=\"122\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><path d=\"M672 40 L672 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"700\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the surprises all land here</text><path d=\"M20 186 L700 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"210\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">together: everybody in from the start</text><text x=\"20\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">product</text><rect x=\"140\" y=\"232\" width=\"420\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">design</text><rect x=\"160\" y=\"258\" width=\"400\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">development</text><rect x=\"180\" y=\"284\" width=\"380\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"319\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">QA</text><rect x=\"200\" y=\"310\" width=\"360\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><circle cx=\"240\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"340\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"440\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"540\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"140\" y=\"354\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">small surprises, found each week</text></svg>", "caption": "The work is the same in both. What changes is when each person first sees it."}
```

In a **relay**, each role finishes its part and hands it to the next: product writes the ticket, design
draws, development builds, QA tests. It looks efficient, because nobody waits for anybody. But every
handover loses something, and nothing that was lost is noticed until the last person in the line
tries to use the result. The surprises all land at the end, where they cost the most, and each one gets
there looking like somebody else's fault.

When everybody is involved **from the start**, the same misunderstandings still happen, but each is found a
few days after it begins, while it is one sentence to fix: *"shop only? then I won't build the online part."*
That is the whole argument of this lesson, and it is the same argument lesson 17 made about the ladder: **the
earlier a problem is caught, the less it costs.**
