---
title: Choosing with @switch, and the case nobody wrote
version: 1
---

**`@switch (value)` draws the one `@case` whose value matches, or `@default` when none does.** It is
`@if` for a value with several known possibilities, and the planner has one: a session is done,
missed, or still planned. Put a status on the bench:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

type Status = 'done' | 'missed' | 'planned';

@Component({
  selector: 'app-bench',
  imports: [],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected status: Status = 'missed';
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
@switch (status) {
  @case ('done') {
    <p>Done.</p>
  }
  @case ('missed') {
    <p>Missed: the date has passed.</p>
  }
  @default {
    <p>Planned.</p>
  }
}
<button type="button" (click)="status = 'done'">Mark done</button>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Mark done'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Mark done
Bench

Done.

Mark done
```

Matching uses `===`, so `@case ('Done')` would never match `'done'`, and there is no falling through
from one case into the next: exactly one block is drawn.

## When the default should not exist

`@default` catches a value nobody wrote a case for. That is a safety net, and it is also a place
where a new status can hide. Add `'skipped'` to `Status` next month, and `@default` draws "Planned."
for every skipped session without a word. Angular 21 can make that a build error instead. Replace
the default with `@default never;`, and add the fourth status the type allows without a case for it:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
@switch (status) {
  @case ('done') {
    <p>Done.</p>
  }
  @case ('missed') {
    <p>Missed: the date has passed.</p>
  }
  @default never;
}
<button type="button" (click)="status = 'done'">Mark done</button>
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep ERROR
✘ [ERROR] TS2322: Type '"planned"' is not assignable to type 'never'. [plugin angular-compiler]
```

`never` is TypeScript's type for "no value can be here", and the compiler checked that every value
the type allows has a case. `'planned'` had none, and the build named it. **Use `@default never;` when
the type lists every possibility**, so that the next person to add one is told where to draw it.
