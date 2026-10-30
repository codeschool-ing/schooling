---
title: The validators that come with Angular
version: 1
---

**A validator is a function that looks at a control and answers either `null`, for valid, or an
object naming what is wrong.** Angular runs a control's validators every time its value changes,
and the control's `status` follows from the answers: `VALID`, `INVALID`, or `PENDING` while an
asynchronous one is still working. A group is invalid if any control inside it is. Lesson 14's form
sent an empty date to the server and let the server refuse it; the same form with validators knows
before anything is sent.

`Validators` holds the common ones: `required`, `min` and `max` for numbers, `minLength` and
`maxLength` for strings, `email`, and `pattern` for a regular expression. A control takes them as
its second argument, alone or in a list. The date control is now made by a small method, since
`addDate` makes the same control as the group does, and a line under the form reports what the
validators say:

```typescript
// src/app/add-session/add-session.ts
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { concatMap, from } from 'rxjs';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      <h3>Add sessions</h3>
      <div formArrayName="dates">
        @for (date of form.controls.dates.controls; track date; let i = $index) {
          <label [for]="'date-' + i">Date {{ i + 1 }}</label>
          <input [id]="'date-' + i" type="date" [formControlName]="i" />
          @if (form.controls.dates.length > 1) {
            <button type="button" (click)="form.controls.dates.removeAt(i)">Remove date {{ i + 1 }}</button>
          }
        }
      </div>
      <button type="button" (click)="addDate()">Another date</button>
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
      <button type="submit">Add</button>
      @if (error(); as message) {
        <p role="alert">{{ message }}</p>
      }
    </form>
    <p>{{ report() }}</p>
  `,
  styles: `
    form,
    div {
      display: grid;
      gap: 0.5rem;
      max-width: 20rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AddSession {
  readonly courseId = input.required<string>();
  private readonly store = inject(PlannerStore);
  private readonly fb = inject(NonNullableFormBuilder);
  protected readonly error = signal<string | null>(null);

  protected readonly form = this.fb.group({
    dates: this.fb.array([this.dateControl()]),
    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),
  });

  protected report(): string {
    return `${this.form.status}; minutes: ${JSON.stringify(this.form.controls.minutes.errors)}`;
  }

  protected addDate(): void {
    this.form.controls.dates.push(this.dateControl());
  }

  protected submit(): void {
    if (this.form.invalid) return;
    this.error.set(null);
    const { dates, minutes } = this.form.getRawValue();
    from(dates)
      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))
      .subscribe({
        complete: () => this.startAgain(),
        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),
      });
  }

  private dateControl() {
    return this.fb.control('', { validators: Validators.required });
  }

  private startAgain(): void {
    this.form.controls.dates.clear();
    this.addDate();
    this.form.reset();
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = 2'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 2
Add sessions
Date 1
Another date
Minutes
Add

INVALID; minutes: {"min":{"min":5,"actual":2}}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = '
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 
Add sessions
Date 1
Another date
Minutes
Add

INVALID; minutes: {"required":true}
```

**Each validator that fails adds its own key to `errors`.** `min` says what the minimum was and what
the value was, `required` says only `true`. The group stays `INVALID` in both, and would stay so with
good minutes too, because the date is still empty and also `required`. `submit` now stops there, so
an empty date never reaches the server again.

That is better for the server and worse for the person: the button does nothing, and nothing on the
page says why. The numbers in `errors` are for code to read. The next section turns them into
sentences, and puts each one where a person, and a screen reader, will find it.

Angular also adds `novalidate` to every form it manages, which turns off the browser's own
validation bubbles. They cannot be styled, say different things in every browser, and are not
announced the same way by every screen reader, so the form shows its own messages instead.
