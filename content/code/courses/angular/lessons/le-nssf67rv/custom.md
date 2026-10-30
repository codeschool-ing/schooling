---
title: Validators of your own
version: 1
---

**A validator of your own is a function with the same shape as Angular's: it takes a control and
returns `null` or an errors object.** Nothing registers it; it is passed to a control like
`Validators.required` is. Two rules the planner wants have no built-in validator: a session cannot
be planned on a day that has already gone, and the dates in one submission should not repeat.

They go in a file of their own, because neither is about this one form:

```schooling-example
{"language": "typescript", "file": "src/app/validators.ts", "parts": [
 {"code": "// src/app/validators.ts\nimport { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';\n\nexport function notBefore(day: string): ValidatorFn {\n  return (control: AbstractControl<string>): ValidationErrors | null =>\n    control.value !== '' && control.value < day ? { past: { day } } : null;\n}", "note": "A validator that needs a setting is a function that returns the validator. `notBefore(day)` makes one for a given day; the error carries the day, as `min` carries its minimum."},
 {"code": "export const distinctDates: ValidatorFn = (array: AbstractControl<string[]>): ValidationErrors | null => {\n  const filled = array.value.filter((date) => date !== '');\n  return new Set(filled).size < filled.length ? { repeated: true } : null;\n};", "note": "A validator on the array sees all its values at once, which is the only place a rule about two dates together can be checked. Empty dates are left to `required`."}
]}
```

`control.value < day` compares two strings, and for dates in the form `YYYY-MM-DD` that is the same
as comparing the dates, because the digits run from the largest unit to the smallest. An empty date
is not "before" anything; it is missing, which is `required`'s business, so `notBefore` leaves it
alone rather than giving a second message for one problem.

The form uses lesson 10's `TODAY` for the day, so a test can name it and `--today` sets it:

```typescript
// src/app/add-session/add-session.ts
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';
import { AbstractControl, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { concatMap, from } from 'rxjs';
import { isoDay } from '../planner';
import { PlannerStore } from '../planner-store';
import { TODAY } from '../today';
import { distinctDates, notBefore } from '../validators';

const MESSAGES: Record<string, string> = {
  required: 'This is needed.',
  min: 'At least 5 minutes.',
  max: 'At most 480 minutes.',
  past: 'That day has already gone.',
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
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);
  private readonly today = isoDay(inject(TODAY));
  protected readonly error = signal<string | null>(null);
  protected readonly submitted = signal(false);

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

A date before the 23rd:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-add-session --do 'fill Date 1 = 2026-10-20' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date 1 = 2026-10-20
-- click Add
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [invalid] [focused]: 2026-10-20 (description: That day has already gone.)
  - paragraph
    - text: That day has already gone.
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes": 30
  - button "Add"
```

And the same day twice:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-add-session --do 'fill Date 1 = 2026-10-26' --do 'click Another date' --do 'fill Date 2 = 2026-10-26' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date 1 = 2026-10-26
-- click Another date
-- fill Date 2 = 2026-10-26
-- click Add
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [focused]: 2026-10-26
  - button "Remove date 1"
  - LabelText
    - text: Date 2
  - Date "Date 2": 2026-10-26
  - button "Remove date 2"
  - paragraph
    - text: Two of the dates are the same day.
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes": 30
  - button "Add"
```

The array's message sits under the dates, and neither date is marked invalid, because neither is
wrong on its own: it is the pair. `focusFirstProblem` falls back to the first date, which is where a
person would start looking.
