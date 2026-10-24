---
title: Which injector answers
version: 1
---

**An Angular application has a tree of injectors, not one, and a question goes up the tree until
an injector has a recipe for it.** Every component has an injector of its own, made from its
`providers` list; above them all sits the root injector, made from `app.config.ts` and every
`providedIn: 'root'`; above that, a platform injector shared by the whole page, and at the top a
last one that answers anything by throwing `NG0201`. Where a recipe sits decides who shares what it
makes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"The injector tree, from the top. NullInjector, which answers anything by throwing NG0201. Below it the platform injector, shared by the page. Below that the root injector, made from app.config.ts and every providedIn root. Below that, one injector per component: App, then Bench, then two Counters, each asking for a Tally. A dashed arrow from a Counter goes up: inject(Tally) starts at the Counter&#x27;s own injector, passes every one with no recipe for it, and the root injector answers.\"><rect x=\"150\" y=\"16\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">NullInjector</text><text x=\"300.0\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">answers anything by throwing NG0201</text><rect x=\"150\" y=\"82\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">platform injector</text><text x=\"300.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">shared by the whole page</text><rect x=\"150\" y=\"148\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">root injector</text><text x=\"300.0\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app.config.ts · providedIn: 'root'</text><line x1=\"300.0\" y1=\"82\" x2=\"300.0\" y2=\"62\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,62.0 303.1,69.4 296.9,69.4\" fill=\"var(--wire)\"></polygon><line x1=\"300.0\" y1=\"148\" x2=\"300.0\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,128.0 303.1,135.4 296.9,135.4\" fill=\"var(--wire)\"></polygon><text x=\"210\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">one per component</text><rect x=\"225\" y=\"214\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"300.0\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its providers</text><rect x=\"225\" y=\"270\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bench</text><text x=\"300.0\" y=\"301\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its providers</text><rect x=\"120\" y=\"326\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"341\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Counter</text><text x=\"205.0\" y=\"357\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">asks for a Tally</text><rect x=\"310\" y=\"326\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"341\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Counter</text><text x=\"395.0\" y=\"357\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">asks for a Tally</text><line x1=\"300.0\" y1=\"212\" x2=\"300.0\" y2=\"194\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,194.0 303.1,201.4 296.9,201.4\" fill=\"var(--wire)\"></polygon><line x1=\"300.0\" y1=\"268\" x2=\"300.0\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,256.0 303.1,263.4 296.9,263.4\" fill=\"var(--wire)\"></polygon><line x1=\"205\" y1=\"324\" x2=\"260\" y2=\"312\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,312.0 253.5,316.6 252.1,310.5\" fill=\"var(--wire)\"></polygon><line x1=\"395\" y1=\"324\" x2=\"340\" y2=\"312\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"340.0,312.0 347.9,310.5 346.5,316.6\" fill=\"var(--wire)\"></polygon><path d=\"M 480 346 L 520 346 L 520 170 L 454 170\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></path><line x1=\"464\" y1=\"170\" x2=\"454\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"454.0,170.0 461.4,166.9 461.4,173.1\" fill=\"var(--amber)\"></polygon><text x=\"532\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inject(Tally)</text><text x=\"532\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">starts at the Counter's own,</text><text x=\"532\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passes every one with no recipe,</text><text x=\"532\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and the root answers</text></svg>", "caption": "A question starts at the asking component and goes up; the first injector with a recipe answers, and the one at the top answers with an error."}
```

The greeters are about to go, so `app.config.ts` goes back first to what git has:

```
ana@dev:~/planner$ git checkout -- src/app/app.config.ts
```

A counter shows the tree at work. `Tally` holds a number in a signal, and `Counter` shows a tally and adds to it.
The bench puts two counters side by side:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, input, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-counter',
  template: `
    <p>{{ name() }}: {{ tally.count() }}</p>
    <button type="button" (click)="tally.count.set(tally.count() + 1)">Add to {{ name() }}</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Counter {
  readonly name = input.required<string>();
  protected readonly tally = inject(Tally);
}

@Component({
  selector: 'app-bench',
  imports: [Counter],
  template: '<app-counter name="first" /><app-counter name="second" />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add to first'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add to first
first: 1

Add to first

second: 1

Add to second
```

One click, and both counters say 1. Neither counter's injector has a recipe for `Tally`, nor does
the bench's, so both questions went up to the root, which made one `Tally` and gave it to both.
That is what `providedIn: 'root'` means: one instance for the whole application.

## A recipe lower down

Give `Counter` a `providers` list of its own and its injector has the recipe, so the question
stops there. One line changes, in `Counter`'s decorator:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, input, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-counter',
  providers: [Tally],
  template: `
    <p>{{ name() }}: {{ tally.count() }}</p>
    <button type="button" (click)="tally.count.set(tally.count() + 1)">Add to {{ name() }}</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Counter {
  readonly name = input.required<string>();
  protected readonly tally = inject(Tally);
}

@Component({
  selector: 'app-bench',
  imports: [Counter],
  template: '<app-counter name="first" /><app-counter name="second" />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add to first'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add to first
first: 1

Add to first

second: 0

Add to second
```

Now each counter has a `Tally` of its own, made when the counter is made and thrown away when it is
destroyed. The root's `Tally` still exists as a recipe, and nobody reaches it, because every
question stops one level down.

| where the recipe is | who shares one instance | how long it lives |
|---|---|---|
| `providedIn: 'root'`, or `app.config.ts` | the whole application | as long as the application |
| a component's `providers` | that component and everything inside its template | as long as that component |
| a test's `providers` | everything the test builds | one test |

**This is the decision lesson 11 turns on.** `Week` and `CoursePage` each load the planner's data
for themselves, so ticking a session done on the course page leaves the week's total where it was:
two copies that disagree. One instance in the root, asked for by both, is one copy.
