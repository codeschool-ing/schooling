---
title: model, when a value goes both ways
version: 1
---

**`model()` declares a value that the parent passes down and the child can change, and the change
flows back up into the parent's signal.** It is an input and an output in one, and the template binds
it with both brackets at once, `[(value)]="signal"`, which people call the banana in a box. It suits a
component that behaves like a form control: a stepper, a toggle, a date picker, where the parent hands
over a value and wants it back edited.

The planner has no such control yet, so this is a bench, generated with its template inline:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, model, signal } from '@angular/core';

@Component({
  selector: 'app-stepper',
  template: `
    <button type="button" (click)="value.update((v) => v - 5)">5 fewer</button>
    {{ value() }} minutes
    <button type="button" (click)="value.update((v) => v + 5)">5 more</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Stepper {
  readonly value = model(30);
}

@Component({
  selector: 'app-bench',
  imports: [Stepper],
  template: `
    <h2>Bench</h2>
    <app-stepper [(value)]="minutes" />
    <p>The bench holds {{ minutes() }}.</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly minutes = signal(45);
}
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click 5 more' --do 'click 5 more'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click 5 more
-- click 5 more
Bench
5 fewer 55 minutes 5 more

The bench holds 55.
```

The bench's `minutes` started at 45, which replaced the stepper's own default of 30, and two clicks
inside the stepper moved the bench's signal to 55. **The child wrote, and the parent's value changed.**
`[(value)]="minutes"` is shorthand for `[value]="minutes()"` plus `(valueChange)="minutes.set($event)"`:
`model` declares the output `valueChange` for you.

## When not to use it

Two-way binding hides who owns the value: the parent holds the signal, and the child changes it. For a
control that is the point. For the planner's sessions it would be wrong: a row that set `done` on its
parent's data directly would bypass the owner, which the previous section's output kept in charge.
**Use `model` for a control's value, and an input with an output for data that belongs to somebody.**
