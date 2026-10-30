---
title: Vector clocks, when there is no single counter
version: 1
---

**A version number works because one server does the counting; a vector clock works without
one.** Each device keeps its own counter for each row, and the row carries all of them. Comparing
two such clocks tells you whether one write had seen the other, in either direction, or neither.
It needs no server in the middle, which matters when two devices sync with each other directly, or
when several servers each accept writes and exchange them later.

The rules fit in three functions. Save this as `vclock.ts` in `~/planner/versions`:

```typescript
// vclock.ts: vector clocks, one counter per device that has written.
export type Clock = Record<string, number>;

// A device's write: its own counter goes up by one.
export const tick = (c: Clock, device: string): Clock => ({ ...c, [device]: (c[device] ?? 0) + 1 });

// What a device knows after receiving another's row: the larger counter of each.
export function merge(a: Clock, b: Clock): Clock {
  const out: Clock = { ...a };
  for (const [k, n] of Object.entries(b)) out[k] = Math.max(out[k] ?? 0, n);
  return out;
}

// a is before b if b has seen everything a has, and more; neither, and they are concurrent.
export function compare(a: Clock, b: Clock): "equal" | "before" | "after" | "concurrent" {
  let less = false;
  let more = false;
  for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
    if ((a[k] ?? 0) < (b[k] ?? 0)) less = true;
    if ((a[k] ?? 0) > (b[k] ?? 0)) more = true;
  }
  return less && more ? "concurrent" : less ? "before" : more ? "after" : "equal";
}
```

A **tick** is a write: the writing device raises its own entry. A **merge** is what a device does
when it receives somebody else's row: it takes the larger value of every entry, so its clock now
says it has seen everything the other had. And **compare** looks at every entry: if one clock is
behind on some and ahead on none, it is before the other; if each is ahead somewhere, they are
concurrent, and that is a conflict.

Here are the two mornings: Wednesday, when both devices edited `s3` offline from the same row, and
Thursday, when the tablet pulled the phone's change before making its own. Save it as `clocks.ts`:

```typescript
// clocks.ts: the two mornings of this lesson, as vector clocks on s3.
import { tick, merge, compare, type Clock } from "./vclock.ts";

const show = (c: Clock) => JSON.stringify(c);

// Wednesday: both devices edit offline, from the same row.
const start: Clock = {};
const phone = tick(start, "phone");
const tablet = tick(start, "tablet");
console.log(`wednesday  phone ${show(phone)}  tablet ${show(tablet)}  -> ${compare(phone, tablet)}`);

// Thursday: the tablet pulls the phone's row first, then edits.
const pulled = merge(start, phone);
const later = tick(pulled, "tablet");
console.log(`thursday   phone ${show(phone)}  tablet ${show(later)}  -> ${compare(phone, later)}`);
console.log(`           tablet ${show(later)}  phone ${show(phone)}  -> ${compare(later, phone)}`);
```

```
ana@dev:~/planner/versions$ node clocks.ts
wednesday  phone {"phone":1}  tablet {"tablet":1}  -> concurrent
thursday   phone {"phone":1}  tablet {"phone":1,"tablet":1}  -> before
           tablet {"phone":1,"tablet":1}  phone {"phone":1}  -> after
```

On Wednesday, `{"phone":1}` and `{"tablet":1}` are each ahead in one entry, so neither had seen
the other: **concurrent**. On Thursday the tablet's clock is `{"phone":1,"tablet":1}`, which covers
the phone's and adds to it, so the phone's write is **before** the tablet's and the tablet's simply
replaces it. No timestamp was read on either day, and a phone two hours fast would get the same
answers.

## What a vector clock costs

The clock grows by one entry for every device that has ever written the row. A planner used on a
phone and a tablet carries two numbers per row; a shared document edited by forty people carries
forty, and an entry for a phone that was lost in 2025 stays until something decides it is safe to
drop. Systems that use them, starting with Amazon's Dynamo, prune old entries or use refinements
such as dotted version vectors, and the details are their own subject.

**A vector clock detects a conflict; it does not resolve one.** "Concurrent" tells the device that
two versions both have to be looked at. What to keep from each is the next section, and it is the
same work whether the conflict was found by a version number or by a clock.

For the planner, which syncs through one server, the version number of the previous section is
enough, and it is one integer per row. Reach for vector clocks when there is no single place that
sees every write first.
