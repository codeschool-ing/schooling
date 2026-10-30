---
title: An asynchronous validator, and pending
version: 1
---

**Some rules can only be checked by asking somebody else.** Whether the course already has a session
on a day is a question for the server: the store has a copy, but another tab, or another person
using the same planner, may have added one since the copy was loaded. An **asynchronous validator**
returns an Observable of the answer instead of the answer, and while it is waiting the control's
status is `PENDING`.

Two things come with it. Angular runs a control's synchronous validators first and the asynchronous
ones only if those pass, so an empty or past date never costs a request. And an asynchronous
validator runs on every change of the value, which for a field that changes with every key would be
a request per key. `updateOn: 'blur'` changes when the control takes its value from the input: on
leaving the field rather than on every key, so the server is asked once per date. A submit takes
the values of every field too, so pressing Enter in a field still sends what it holds.

```typescript
// src/app/add-session/add-session.ts
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';
import { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { concatMap, filter, from, map, take } from 'rxjs';
import { PlannerData, isoDay } from '../planner';
import { PlannerStore } from '../planner-store';
import { TODAY } from '../today';
import { distinctDates, notBefore } from '../validators';

const MESSAGES: Record<string, string> = {
  required: 'This is needed.',
  min: 'At least 5 minutes.',
  max: 'At most 480 minutes.',
  past: 'That day has already gone.',
  taken: 'This course already has a session that day.',
};

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      <h3>Add sessions</h3>
      <div formArrayName="dates">
        @for (date of form.controls.dates.controls; track date; let i = $index) {
          <label [for]="'date-' + i">Date {{ i + 1 }}</label>
          <input
            [id]="'date-' + i"
            type="date"
            [formControlName]="i"
            [aria-invalid]="shows(date)"
            [aria-describedby]="shows(date) ? 'date-' + i + '-error' : null"
          />
          @if (shows(date)) {
            <p [id]="'date-' + i + '-error'">{{ messageFor(date) }}</p>
          }
          @if (form.controls.dates.length > 1) {
            <button type="button" (click)="form.controls.dates.removeAt(i)">Remove date {{ i + 1 }}</button>
          }
        }
        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {
          <p>Two of the dates are the same day.</p>
        }
      </div>
      <button type="button" (click)="addDate()">Another date</button>
      <label for="minutes">Minutes</label>
      <input
        id="minutes"
        type="number"
        formControlName="minutes"
        [aria-invalid]="shows(form.controls.minutes)"
        [aria-describedby]="shows(form.controls.minutes) ? 'minutes-error' : null"
      />
      @if (shows(form.controls.minutes)) {
        <p id="minutes-error">{{ messageFor(form.controls.minutes) }}</p>
      }
      <button type="submit">Add</button>
      @if (error(); as message) {
        <p role="alert">{{ message }}</p>
      }
    </form>
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
  private readonly http = inject(HttpClient);
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);
  private readonly today = isoDay(inject(TODAY));
  protected readonly error = signal<string | null>(null);
  protected readonly submitted = signal(false);

  private readonly freeDay: AsyncValidatorFn = (control) =>
    this.http
      .get<PlannerData>('/api/planner')
      .pipe(
        map((data) =>
          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,
        ),
      );

  protected readonly form = this.fb.group({
    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),
    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),
  });

  protected shows(control: AbstractControl): boolean {
    return control.invalid && (control.touched || this.submitted());
  }

  protected messageFor(control: AbstractControl): string {
    const first = Object.keys(control.errors ?? {})[0];
    return MESSAGES[first] ?? first;
  }

  protected addDate(): void {
    this.form.controls.dates.push(this.dateControl());
  }

  protected submit(): void {
    this.submitted.set(true);
    if (this.form.pending) {
      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());
      return;
    }
    if (this.form.invalid) {
      this.focusFirstProblem();
      return;
    }
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
    return this.fb.control('', {
      validators: [Validators.required, notBefore(this.today)],
      asyncValidators: this.freeDay,
      updateOn: 'blur',
    });
  }

  private focusFirstProblem(): void {
    const { dates, minutes } = this.form.controls;
    const i = dates.controls.findIndex((date) => date.invalid);
    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;
    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();
  }

  private startAgain(): void {
    this.submitted.set(false);
    this.form.controls.dates.clear();
    this.addDate();
    this.form.reset();
  }
}
```

`submit` has to wait for a check still out. Clicking the button leaves the date field, the blur sets
the value, the asynchronous validator starts, and `submit` runs in the same moment with the form
`PENDING`, neither valid nor invalid. So `submit` waits for the first status that is not `PENDING`
and runs again then. Saturday the 24th already has the JavaScript session:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-add-session --network --do 'fill Date 1 = 2026-10-24' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- fill Date 1 = 2026-10-24
-- click Add
net  GET /api/planner  200
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [invalid] [focused]: 2026-10-24 (description: This course already has a session that day.)
  - paragraph
    - text: This course already has a session that day.
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes": 30
  - button "Add"
```

Two requests for the planner: the store's when the page loaded, and the validator's when the date
field was left. The answer said the day was taken, `submit` ran again on the new status, and the
focus went to the date.
