---
title: A counter and a set that cannot lose an edit
version: 1
---

**The trick in both is the same: never send a value that replaces another, only facts that add
up.** Lesson 13's counter lost 45 minutes because each device sent its total, and two totals
cannot be combined. Send instead how much *each device* has added, and the merge is obvious: keep
the larger count for every device, and the total is their sum. Nothing is ever overwritten,
because each device only ever writes its own entry.

The set uses the same idea for a harder case. Removing an item and adding one are opposite
operations, so a device that removed `weekly` and a device that added `exam` cannot both be
honoured by comparing two lists. The **observed-remove set** gives every add a unique tag, and a
remove deletes only the tags its device had seen. An add made somewhere else, which the remover
never saw, carries a tag the remove does not mention, so it survives.

Make the folder `~/planner/crdt` and save this there as `crdt.ts`:

```schooling-example
{"language": "typescript", "file": "crdt.ts", "parts": [{"code": "// crdt.ts: a counter and a set whose copies always merge to the same state.\n"}, {"code": "// A grow-only counter: each device counts its own additions, and the total is the sum.\nexport type GCounter = Record<string, number>;\nexport const add = (c: GCounter, device: string, n: number): GCounter => ({ ...c, [device]: (c[device] ?? 0) + n });\nexport const total = (c: GCounter) => Object.values(c).reduce((a, b) => a + b, 0);", "note": "A grow-only counter is one count per device. `add` raises only the writing device's entry, and the total is the sum of them all."}, {"code": "export function mergeCounter(a: GCounter, b: GCounter): GCounter {\n  const out = { ...a };\n  for (const [d, n] of Object.entries(b)) out[d] = Math.max(out[d] ?? 0, n);\n  return out;\n}\n", "note": "The merge keeps the larger count for each device. Taking a maximum is commutative, associative and idempotent, which is the whole guarantee."}, {"code": "// An observed-remove set: every add gets a tag, and a remove deletes only the tags it has seen.\nexport type ORSet = { adds: Record<string, string[]>; removed: string[] };\nexport const empty = (): ORSet => ({ adds: {}, removed: [] });\nexport function insert(s: ORSet, value: string, tag: string): ORSet {\n  return { ...s, adds: { ...s.adds, [value]: [...(s.adds[value] ?? []), tag] } };\n}\nexport function remove(s: ORSet, value: string): ORSet {\n  return { ...s, removed: [...s.removed, ...(s.adds[value] ?? [])] };\n}", "note": "The observed-remove set. Each add records a tag beside the value; a remove marks as removed only the tags this copy holds, which are the adds it has seen."}, {"code": "export function values(s: ORSet): string[] {\n  return Object.keys(s.adds).filter((v) => s.adds[v].some((t) => !s.removed.includes(t))).sort();\n}", "note": "A value is in the set while at least one of its tags has not been removed."}, {"code": "export function mergeSet(a: ORSet, b: ORSet): ORSet {\n  const adds: Record<string, string[]> = {};\n  for (const v of new Set([...Object.keys(a.adds), ...Object.keys(b.adds)])) {\n    adds[v] = [...new Set([...(a.adds[v] ?? []), ...(b.adds[v] ?? [])])].sort();\n  }\n  return { adds, removed: [...new Set([...a.removed, ...b.removed])].sort() };\n}", "note": "The merge is a union of the adds and a union of the removes. Unions are commutative, associative and idempotent too, and `sort` keeps the stored order the same whatever came first."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-counter\" aria-label=\"A grow-only counter of minutes studied. Both devices last synced phone 60 and tablet 40, a total of 100. Offline, the phone adds 30: its copy reads phone 90, tablet 40, total 130. The tablet adds 45: its copy reads phone 60, tablet 85, total 145. The merge keeps the larger count for each device: phone 90, tablet 85, total 175, whichever copy is merged into which.\"><defs><marker id=\"l15-counter-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-counter-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"105\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">as both last synced</text><rect x=\"20\" y=\"100\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"176\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60</text><text x=\"34\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"176\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"34\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"176\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">100</text><text x=\"355\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the phone adds 30</text><rect x=\"270\" y=\"30\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"284\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"426\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90</text><text x=\"284\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"426\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"284\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"426\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">130</text><text x=\"355\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the tablet adds 45</text><rect x=\"270\" y=\"160\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"284\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"426\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60</text><text x=\"284\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"426\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">85</text><text x=\"284\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"426\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">145</text><text x=\"615\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">merged: the larger count per device</text><rect x=\"530\" y=\"100\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"544\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"686\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90</text><text x=\"544\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"686\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">85</text><text x=\"544\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"686\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">175</text><path d=\"M190 125 L270 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-paper-dim)\"></path><path d=\"M190 150 L270 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-paper-dim)\"></path><path d=\"M440 70 L530 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-phosphor)\"></path><path d=\"M440 200 L530 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-phosphor)\"></path></svg>", "caption": "Each device only ever writes its own entry, so the merge has nothing to choose between: it keeps the larger count for each device, and the total is their sum."}
```

Now the two devices of lesson 13, with the two kinds of data that rule lost. The minutes studied
this month were 100 when both last synced, 60 counted on the phone and 40 on the tablet. The Guitar
course's tags were just `weekly`. Then, offline, each device does its own thing. Save it as
`merges.ts`:

```typescript
// merges.ts: two devices change a counter and a set offline, then merge in every order.
import { add, total, mergeCounter, empty, insert, remove, values, mergeSet } from "./crdt.ts";

// Minutes studied this month, as both devices last synced it: 100.
const synced = { phone: 60, tablet: 40 };
const phone = add(synced, "phone", 30);
const tablet = add(synced, "tablet", 45);
console.log("minutes  phone", total(phone), " tablet", total(tablet));
console.log("  phone + tablet          ", total(mergeCounter(phone, tablet)));
console.log("  tablet + phone          ", total(mergeCounter(tablet, phone)));
console.log("  phone + tablet + tablet ", total(mergeCounter(mergeCounter(phone, tablet), tablet)));

// The Guitar course's tags, as both devices last synced them.
const tags = insert(empty(), "weekly", "a1");
const p = insert(tags, "exam", "p1"); // the phone adds a tag
const t = insert(remove(tags, "weekly"), "evening", "t1"); // the tablet removes one and adds one
console.log("tags     phone", values(p).join(", "), " tablet", values(t).join(", "));
console.log("  phone + tablet          ", values(mergeSet(p, t)).join(", "));
console.log("  tablet + phone          ", values(mergeSet(t, p)).join(", "));

// The same tag, added again on the phone while the tablet removes it.
const p2 = insert(tags, "weekly", "p2");
console.log("  re-added on one, removed on the other:", values(mergeSet(p2, t)).join(", "));
```

The tags `a1`, `p1`, `t1` and `p2` are written out so the run is the same every time; an app would
generate a random one per add, as the device-made ids of lesson 4 are. Merge each pair both ways,
and the counter once more with an update it already had:

```
ana@dev:~/planner/crdt$ node merges.ts
minutes  phone 130  tablet 145
  phone + tablet           175
  tablet + phone           175
  phone + tablet + tablet  175
tags     phone exam, weekly  tablet evening
  phone + tablet           evening, exam
  tablet + phone           evening, exam
  re-added on one, removed on the other: evening, weekly
```

**175 in every order, and 175 again when the tablet's update arrives twice.** That is the three
properties of the previous section, visible: the order did not matter and the repeat did nothing.
The tags converge as well, to `evening, exam`: the tablet's removal of `weekly` and the phone's
addition of `exam` both took effect, and so did the tablet's own addition.

The last line is the case worth reading twice. The phone added `weekly` again, with a new tag `p2`,
while the tablet was removing it. The tablet's remove covered `a1`, the only tag it had seen, so
`p2` survives and `weekly` stays. **When an add and a remove of the same item are concurrent, the
add wins.** That is a rule somebody chose, and it is the right one for tags: a tag that reappears is
an annoyance, and a tag that vanishes after you added it is a bug report.

## What the counter cannot do

A grow-only counter only adds. Minutes studied never go down, so it fits; a balance that can go
down needs two of them, one for additions and one for subtractions, and the value is the
difference. That pair is called a PN-counter. What neither can do is refuse: no merge can stop two
offline devices from each spending the last ten minutes of a budget. A rule that must hold across
all devices, at every moment, needs one place that says yes or no, which is a server, and the
outbox of lesson 8 already sends it the question.
