---
title: Stretch, with a net
version: 1
---

**People grow on work slightly beyond what they can do alone, with help close enough to reach.** Too
easy and nothing is learned; too far and the person fails in public and learns to avoid the next
stretch. The mentor's skill is choosing the distance and staying within reach.

## The zone where learning happens

The psychologist Lev Vygotsky called the space between what a learner can do alone and what they can
do with help the *zone of proximal development*. His subject was children, and the idea transfers
well: a task inside the zone is one Diego could not yet finish alone but can finish with a question or
two at the right moment.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three nested circles. The inner one, alone: what Diego already can do, such as writing the code. The middle ring, with help: leading the delivery-slot change. The outer ring, not yet: redesigning everybody&#x27;s quotas.\"><defs><marker id=\"zpd-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"300\" cy=\"135\" r=\"120\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></circle><circle cx=\"300\" cy=\"135\" r=\"78\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle><circle cx=\"300\" cy=\"135\" r=\"40\" fill=\"var(--ink)\" stroke=\"var(--wire)\"></circle><text x=\"300\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alone</text><text x=\"300\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">already can</text><text x=\"300\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">with help</text><text x=\"300\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">not yet</text><path d=\"M470 135 L326 135\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zpd-ah)\"></path><text x=\"480\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writing the code</text><path d=\"M470 80 L358 95\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zpd-ah)\"></path><text x=\"480\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">leading the delivery-slot change</text><path d=\"M470 30 L392 59\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zpd-ah)\"></path><text x=\"480\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">redesigning everybody's quotas</text></svg>", "caption": "Vygotsky's zone of proximal development, applied to three pieces of Diego's work. A stretch assignment sits in the middle ring."}
```

Leading the delivery-slot change was in Diego's zone. Writing the code was below it: he already could.
Designing the change to the orders database's quotas, which touches every team, would have been above
it: there were too many unknowns for one question to unlock.

## How much to hand over

Within a stretch assignment, the mentor decides how much of the decision to hand over, and it can
change step by step. A useful ladder, from least to most handed over:

1. **"Do this, this way."** For the parts where a mistake is expensive and the learning is small.
2. **"Look into it and tell me what you'd do; I'll decide."**
3. **"Decide, and tell me before you act."**
4. **"Decide and act; tell me afterwards."**
5. **"Decide and act; you don't need to tell me."**

On the delivery-slot change, Diego was at 3 for the design and at 4 for the code. The database
migration stayed at 2, because a mistake there reaches production for everybody. **Saying which level
applies to which part, out loud, prevents the two worst surprises**: the junior who waits for
permission they already had, and the one who acts on something they were meant to check.

## The net

A stretch without a net is a test. The net is three things:

- **availability**: Diego knows he can ask, and the two-hour rule means he does;
- **a review before it matters**: Lívia read the design document before the team did, so the first
  public version was already a good one;
- **a failure that is survivable**: the change went to 5% of customers first. A mistake there is
  a lesson, not an incident.

## When it goes wrong

It will, sometimes. The delivery-slot change shipped with a bug in how it showed times near midnight,
found by the 5% rollout. Lívia's response matters more than the bug. **Ask what happened and what he
would do differently before saying anything else**, then help with the fix if asked. The same
questions as a blameless review (lesson 15), at the scale of one person.
