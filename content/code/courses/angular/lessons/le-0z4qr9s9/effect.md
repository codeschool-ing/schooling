---
title: effect, for what a signal does to the outside world
version: 1
---

**`effect(() => …)` runs a function whenever the signals it read last time change, and is for the
one job a `computed` cannot do: acting on something outside Angular.** Writing to `localStorage`,
setting the page's title, logging, drawing on a canvas. If the function *returns* a value somebody
needs, it is a `computed`; an effect returns nothing.

An effect belongs to something that has a lifetime, so it is created in a component, in the class's
fields or its constructor, and stops when the component is destroyed. Give the week's summary one that
logs its numbers, to watch it run:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, effect, signal } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly planned = signal(165);
  protected readonly done = signal(90);

  constructor() {
    effect(() => {
      console.log(`effect: ${this.done()} of ${this.planned()} minutes done`);
    });
  }

  protected markOne(): void {
    this.done.update((d) => d + 15);
  }
}
```

The template reads the signals with parentheses now, and gets a button to change one:

```html
<!-- src/app/week-summary/week-summary.html -->
@let left = planned() - done();
<p>{{ planned() }} minutes planned, {{ done() }} done.</p>
@if (left <= 0) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ left }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done()" [max]="planned()"></progress>
<button type="button" (click)="markOne()">Mark 15 minutes done</button>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary --do 'click Mark 15 minutes done' --do 'click Mark 15 minutes done'
[vite] connecting...
[vite] connected.
effect: 90 of 165 minutes done
Angular is running in development mode.
-- click Mark 15 minutes done
effect: 105 of 165 minutes done
-- click Mark 15 minutes done
effect: 120 of 165 minutes done
165 minutes planned, 120 done.

45 minutes to go.

Done this weekMark 15 minutes done
```

The effect ran once when the component was created, and once after each click. **It does not run
at the moment of the change.** Angular schedules effects and runs them together, after the change and
before the page is drawn, so two changes in a row produce one run, with both applied.

## What an effect is not for

The mistake to avoid is an effect that sets another signal:

```typescript
effect(() => {
  this.left.set(this.planned() - this.done());
});
```

It works, after a fashion: `left` is wrong between the change and the effect's run, and the value has
two sources of truth, the signals and the effect that copies them. `computed(() => this.planned() -
this.done())` is the same thing, always right, with nothing to schedule. **If you are writing a
signal inside an effect, look for the computed you meant.**

The logging effect and the button were for watching; the next section replaces both. Effects you keep
in this course are few: one in lesson 22 saves a preference to `localStorage`, which is exactly the
outside world an effect is for.
