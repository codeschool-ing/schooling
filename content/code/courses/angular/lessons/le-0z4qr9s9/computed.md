---
title: computed, a value derived from others
version: 1
---

**`computed(() => …)` makes a read-only signal whose value is worked out from other signals, and
worked out again only when one of them changes.** It is how a planner turns six sessions into "165
minutes planned" without anybody writing the total down. Two properties make it more than a function
call, and a program that logs every computation shows both:

```typescript
// try/computed.mts
import { computed, signal } from '@angular/core';

const planned = signal(165);
const done = signal(90);
const left = computed(() => {
  console.log('  computing left');
  return planned() - done();
});

console.log('nothing read yet');
console.log('left:', left());
console.log('left again:', left());

done.set(115);
console.log('done changed; nothing read yet');
console.log('left:', left());

planned.set(165);
console.log('planned set to the value it had');
console.log('left:', left());
```

```
ana@dev:~/planner$ node try/computed.mts
nothing read yet
  computing left
left: 75
left again: 75
done changed; nothing read yet
  computing left
left: 50
planned set to the value it had
left: 50
```

**It is lazy.** Creating `left` computed nothing; the first read did. **It is memoised.** The second
read returned the stored 75 without computing again. A change to `done` marked it stale, and the
computation ran at the next read, not at the moment of the change. Setting `planned` to the value it
already had did not mark anything: a signal compares the new value with the old, and an equal one is
not a change.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two signals, planned and done, feed a computed, left, which a template reads. When done is set, a notification travels forward to left, marking it stale, and nothing is computed. When the template next reads left, left pulls the current values of planned and done back and computes once.\"><rect x=\"30\" y=\"40\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">planned</text><text x=\"105.0\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">signal(165)</text><rect x=\"30\" y=\"150\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">done</text><text x=\"105.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">signal(90)</text><rect x=\"290\" y=\"95\" width=\"170\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">left</text><text x=\"375.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">computed</text><rect x=\"560\" y=\"95\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">{{ left() }}</text><text x=\"625.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the template</text><line x1=\"180\" y1=\"63\" x2=\"288\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,108.0 280.0,108.0 282.4,102.3\" fill=\"var(--wire)\"></polygon><line x1=\"180\" y1=\"173\" x2=\"288\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"288.0,130.0 282.3,135.6 280.0,129.8\" fill=\"var(--amber)\"></polygon><line x1=\"460\" y1=\"118\" x2=\"558\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,118.0 550.6,121.1 550.6,114.9\" fill=\"var(--wire)\"></polygon><text x=\"105\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1. done.set(115)</text><text x=\"235\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2. \"left is stale\"</text><path d=\"M558 136 C 520 200, 420 200, 400 145\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"402\" y1=\"150\" x2=\"400\" y2=\"145\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,145.0 405.6,150.7 399.8,153.0\" fill=\"var(--phosphor)\"></polygon><text x=\"500\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">3. the next read pulls</text><text x=\"375\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">4. computes once, then remembers</text></svg>", "caption": "A change only marks what depends on it as stale. The computation happens when somebody reads."}
```

## The dependencies are found by reading

Nothing in `computed` lists `planned` and `done`. Angular recorded which signals the function
**called** while it ran, and those became its dependencies. That has a consequence worth one more
program:

```typescript
// try/branches.mts
import { computed, signal } from '@angular/core';

const showDone = signal(false);
const planned = signal(165);
const done = signal(90);
const label = computed(() => {
  console.log('  computing label');
  return showDone() ? `${done()} done` : `${planned()} planned`;
});

console.log(label());
done.set(100);
console.log('done changed:', label());
showDone.set(true);
console.log('showDone changed:', label());
```

```
ana@dev:~/planner$ node try/branches.mts
  computing label
165 planned
done changed: 165 planned
  computing label
showDone changed: 100 done
```

While `showDone` was false, the function never called `done()`, so `done` was not a dependency, and
changing it did not even mark `label` stale. **A computed depends on what it read last time, not on
everything it could read.** That is efficient, and it is also why the function must read its signals
directly: a signal read inside a `setTimeout` or after an `await` in a computed is not tracked.

A computed is read-only: `left.set(…)` does not exist. If something should be settable and also
follow other values, that is `linkedSignal`, which this course does not need; the planner's derived
values are all plain `computed`.
