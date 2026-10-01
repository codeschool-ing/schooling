---
title: A way to answer
version: 1
---

The answer has four stages, and the first two are worth most of the marks at junior level:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Four stages of an answer to a design question, top to bottom. Clarify: who uses it, how many, and what must never happen. The simplest thing that works: one box, drawn and explained. The one hard part: where it breaks first, and your choice. What would change it: more users, less budget, a new rule.\"><defs><marker id=\"an14-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">clarify</text><text x=\"290\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">who uses it, how many, what must never happen</text><path d=\"M40 56 L40 66\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an14-ah)\"></path><rect x=\"20\" y=\"66\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">simplest thing that works</text><text x=\"290\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one box, drawn and explained</text><path d=\"M40 108 L40 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an14-ah)\"></path><rect x=\"20\" y=\"118\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the one hard part</text><text x=\"290\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where it breaks first, and your choice</text><path d=\"M40 160 L40 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#an14-ah)\"></path><rect x=\"20\" y=\"170\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what would change it</text><text x=\"290\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">more users, less budget, a new rule</text></svg>", "caption": "A junior design answer is judged on the first two stages more than the last two. Nobody expects a junior to design for a million users; everybody expects them to ask how many there are."}
```

**Clarify.** Two or three questions before drawing anything: *how many users? what happens if it is down for
an hour? is there anything that must never happen?* The answers change the design, and asking them is the
single clearest sign that you think like somebody who has built things.

**The simplest thing that works.** Draw it and say it: *one server, one database, a backup copied every
night.* Name each part and what it does. Resist adding a cache, a queue or a second region before anybody
has asked; unnecessary parts read as recited rather than reasoned.

**The one hard part.** Every system has a part that breaks first or a rule that is hard to keep. Say which,
and what you chose: *two people could lend the same item at once, so the database refuses the second loan.*
This is lesson 19 of the portfolio course: the decision, with its reason.

**What would change it.** *If it had a thousand schools instead of one, the single server is the first thing
I'd change.* One sentence, not a second design.
