---
title: ngModel, and a form that lives in the template
version: 1
---

**A template-driven form is built by the template: each `ngModel` on an input makes a control, and
the `<form>` collects them.** There is no `FormGroup` in the class. The class holds plain values,
here two signals, and `[(ngModel)]` keeps each input and its value in step both ways. It is how
Angular forms were written before reactive forms existed, it is still supported, and a great deal
of code you will meet uses it, often for small forms where it reads very naturally.

A bench, for the same two fields lesson 14 began with. Its labels say `Day` and `Length in
minutes`, so they cannot be mistaken for the real form's on the same page:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-bench',
  imports: [FormsModule],
  template: `
    <form>
      <label for="t-day">Day</label>
      <input id="t-day" type="date" name="date" [(ngModel)]="date" />
      <label for="t-minutes">Length in minutes</label>
      <input id="t-minutes" type="number" name="minutes" [(ngModel)]="minutes" />
    </form>
    <p>{{ date() }}, {{ minutes() }} minutes</p>
  `,
  styles: `
    form {
      display: grid;
      gap: 0.5rem;
      max-width: 20rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly date = signal('');
  protected readonly minutes = signal(30);
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
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Day = 2026-10-26' --do 'fill Length in minutes = 45'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Day = 2026-10-26
-- fill Length in minutes = 45
Day
Length in minutes

2026-10-26, 45 minutes
```

**`[( )]` is two bindings in one**: `[ngModel]="date()"` sets the input from the signal, and
`(ngModelChange)` sets the signal from the input. Written with a signal, Angular reads it on the
way in and calls `set` on the way out. Inside a `<form>`, every `ngModel` needs a `name`, which is
the key its value has in the form's value; leaving it out is an error at run time, the first
thing everybody meets with this kind of form.
