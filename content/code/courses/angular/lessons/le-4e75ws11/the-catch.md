---
title: What the template cannot carry
version: 1
---

**A template-driven form exists only once the template has run, and a little after.** The controls
are made by the `ngModel` directives, and each one registers with the form asynchronously, after
the current change detection has finished. A class that asks the form for its value too early gets
an empty object. The bench logs it at two moments:

```typescript
// src/app/bench/bench.ts
import { AfterViewInit, ChangeDetectionStrategy, Component, signal, viewChild } from '@angular/core';
import { FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-bench',
  imports: [FormsModule],
  template: `
    <form #f="ngForm" (ngSubmit)="check(f)">
      <label for="t-day">Day</label>
      <input id="t-day" type="date" name="date" [(ngModel)]="date" required #day="ngModel" />
      @if (day.invalid && (day.touched || f.submitted)) {
        <p>This is needed.</p>
      }
      <label for="t-minutes">Length in minutes</label>
      <input id="t-minutes" type="number" name="minutes" [(ngModel)]="minutes" required min="5" #length="ngModel" />
      @if (length.invalid && (length.touched || f.submitted)) {
        <p>At least 5 minutes.</p>
      }
      <button type="submit">Check</button>
    </form>
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
export class Bench implements AfterViewInit {
  protected readonly date = signal('');
  protected readonly minutes = signal(30);
  private readonly form = viewChild.required(NgForm);

  ngAfterViewInit(): void {
    console.log('after view init:', JSON.stringify(this.form().value));
    setTimeout(() => console.log('a moment later:', JSON.stringify(this.form().value)));
  }

  protected check(f: NgForm): void {
    console.log('submitted:', JSON.stringify(f.value), 'valid:', f.valid);
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
after view init: {}
Angular is running in development mode.
a moment later: {"date":"","minutes":30}
Day
Length in minutes
Check
```

`ngAfterViewInit` is the hook for "the view is drawn", and at that moment the form had no controls
at all. A moment later it had both. Code that sets a value, adds a validator or reads the form from
the class has to know about that gap; with a reactive form there is no gap, because the class made
the controls before the template existed.

The gap is one of four limits, and the other three grow with the form:

| | template-driven | reactive |
|---|---|---|
| where the form is | in the template, made when it runs | in the class, made first |
| the type of a value | `any`: `f.value` is an object nobody described | worked out from the controls |
| a list of fields of changing length | an `@for` of `ngModel`s with generated names | a `FormArray` |
| a test of the rules | render the template and type into it | create the controls and set their values |
| validation | an attribute per rule, and a directive for each custom one | a function per rule, passed to a control |

A rule like lesson 15's `distinctDates` makes the point. Written for a reactive form it is a
function given the array; for a template-driven one it has to be wrapped in a directive, put on an
element around the fields, and given the values through the form it is inside. **The form grows,
and the template-driven version grows faster**, which is the title of this lesson.
