---
title: Data that merges by itself
version: 1
---

The two merges in the last section that lost nothing, the union of the carts and the counter kept
per replica, have something in common. **They do not record values; they record what happened, in a
form where combining two histories has only one sensible answer.** A set of things added merges by
union. A counter made of one entry per replica merges by taking each entry's larger value, because
each entry only ever grows and only its own replica ever changes it.

Data shaped like that has a name: a **CRDT**, conflict-free replicated data type. Its merge has
three properties, and each one removes a problem a distributed system otherwise has to solve:

- **Commutative**: merging A into B gives what merging B into A gives. The order in which two
  replicas hear about each other does not matter.
- **Associative**: merging three copies in any grouping gives one answer, so replicas can gossip in
  any pattern.
- **Idempotent**: merging the same copy twice changes nothing, so a message delivered twice, which
  networks do, is harmless.

With those three, **every replica that has seen the same updates holds the same value**, whatever
order they arrived in. That is eventual consistency with no clock and no coordinator, and no write
lost.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A G-counter merge. Before the partition both replicas hold a: 50, b: 50. During it, replica A raises its own entry to 53 and replica B raises its own to 52. Merging takes the larger value of each entry, giving a: 53, b: 52, a total of 105.\"><rect x=\"40\" y=\"90\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">before</text><text x=\"115\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a:50 b:50</text><path d=\"M190 115 L260 60\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M260 60 L256.9 66.3 L253.2 61.5 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M190 115 L260 170\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M260 170 L253.2 168.5 L256.9 163.7 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"260\" y=\"35\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">replica A, +3</text><text x=\"345\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a:53 b:50</text><rect x=\"260\" y=\"145\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"345\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">replica B, +2</text><text x=\"345\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">a:50 b:52</text><path d=\"M430 60 L500 115\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500 115 L493.2 113.5 L496.9 108.7 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><path d=\"M430 170 L500 115\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M500 115 L496.9 121.3 L493.2 116.5 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"500\" y=\"90\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">merged: max of each</text><text x=\"590\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">a:53 b:52 = 105</text></svg>", "caption": "Each replica only raises its own entry, so taking the larger of each entry never loses a sale."}
```

## The small family

The counter in the program is a **G-counter**, grow-only: `{'a': 53, 'b': 52}`, total 105, every
sale kept. A few relatives cover most of what applications need:

- **PN-counter**: two G-counters, one for increments and one for decrements, and the value is the
  difference. A stock level that goes up and down.
- **G-set**: a set that only grows, merged by union. The cart of the program, if items are never
  removed.
- **OR-set**, observed-remove set: a set where each addition carries a unique tag and a removal
  names the tags it saw. An item removed on one side and added again on the other stays, which is
  what a buyer who re-added it expects.
- **LWW-register**: a single value with a timestamp, merged by last write wins. It is in the family
  because its merge has the three properties too; it is still the one that loses writes.

## What they cannot do

A CRDT guarantees that copies converge. It does not guarantee that the value they converge on
respects a rule. **Two sides that each sell the last seat converge on a counter of capacity plus
one**, perfectly consistent and wrong. Any rule of the form "never more than", "at most one",
"unique" needs the two sides to agree before the write, which is coordination, which is the
consistent choice of section 02 again.

That is the boundary of the whole lesson, and the next section draws it for the box office.
