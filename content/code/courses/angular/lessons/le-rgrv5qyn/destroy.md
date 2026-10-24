---
title: Cleaning up when a component goes
version: 1
---

**When a component is destroyed, anything it started outside Angular keeps going unless it stops it:
a timer, a listener on `window`, a connection.** The `@if` that removed `Life` in the first section
destroyed the component; it did not stop the timers or listeners the component had started, because
Angular does not know about them. A component that starts a clock shows the leak:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';

@Component({
  selector: 'app-clock',
  template: '<p>clock: {{ ticks() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Clock {
  protected readonly ticks = signal(0);

  constructor() {
    setInterval(() => {
      this.ticks.update((t) => t + 1);
      console.log('tick', this.ticks());
    }, 200);
  }
}

@Component({
  selector: 'app-bench',
  imports: [Clock],
  template: `
    <h2>Bench</h2>
    <button type="button" (click)="shown.set(false)">Remove</button>
    @if (shown()) {
      <app-clock />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly shown = signal(true);
}
```

`--do 'wait 500'` lets half a second pass between actions:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'wait 500' --do 'click Remove' --do 'wait 500'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
tick 1
tick 2
-- wait 500
tick 3
tick 4
tick 5
tick 6
tick 7
-- click Remove
tick 8
tick 9
tick 10
-- wait 500
tick 11
tick 12
tick 13
tick 14
tick 15
Bench
Remove
```

The clock left the page, and its interval went on ticking for a component that no longer exists,
holding it in memory so it can never be collected. Do that in a component shown in a list, and every
time the list changes another interval starts and none stops.

## DestroyRef

`inject(DestroyRef)` gives the component the object Angular calls when it is destroyed, and
`onDestroy` registers what to run then:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';

@Component({
  selector: 'app-clock',
  template: '<p>clock: {{ ticks() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Clock {
  protected readonly ticks = signal(0);

  constructor() {
    const id = setInterval(() => {
      this.ticks.update((t) => t + 1);
      console.log('tick', this.ticks());
    }, 200);
    inject(DestroyRef).onDestroy(() => {
      clearInterval(id);
      console.log('clock stopped');
    });
  }
}

@Component({
  selector: 'app-bench',
  imports: [Clock],
  template: `
    <h2>Bench</h2>
    <button type="button" (click)="shown.set(false)">Remove</button>
    @if (shown()) {
      <app-clock />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly shown = signal(true);
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'wait 500' --do 'click Remove' --do 'wait 500'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
tick 1
tick 2
-- wait 500
tick 3
tick 4
tick 5
tick 6
tick 7
-- click Remove
clock stopped
-- wait 500
Bench
Remove
```

The cleanup is written next to what it cleans up, in the constructor, which is easier to keep right
than a start in `ngOnInit` and a stop in a separate `ngOnDestroy` method. `inject` is lesson 10's
subject; here it is enough that it hands the component things Angular holds for it. **What Angular
started, Angular stops**: effects, `resource` requests and the subscriptions of the `async` pipe end
with the component on their own. What you started with a browser API is yours.
