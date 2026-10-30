---
title: Error messages a person can find
version: 1
---

**An error message is shown when it can help, tied to its field so a screen reader reads them
together, and the first field that needs attention gets the focus.** Three decisions, each of which
the form makes in a few lines:

- **When.** A message that appears while somebody is still typing their first digit is noise. The
  rule here is the common one: show a field's message once the field has been left (`touched`), or
  once somebody has tried to submit, whichever comes first.
- **Where.** Under its field, in a paragraph with an id, and the field's `aria-describedby` names
  that id, so a screen reader reads the label, then the message. `aria-invalid` says the field is
  wrong, which a screen reader announces as well.
- **What happens on submit.** Nothing is sent, every message shows, and the focus moves to the first
  field with one. A person who pressed Enter in the last field and heard nothing would otherwise
  have to go looking.

```typescript
// src/app/add-session/add-session.ts
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';
import { AbstractControl, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { concatMap, from } from 'rxjs';
import { PlannerStore } from '../planner-store';

const MESSAGES: Record<string, string> = {
  required: 'This is needed.',
  min: 'At least 5 minutes.',
  max: 'At most 480 minutes.',
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
  protected readonly error = signal<string | null>(null);
  protected readonly submitted = signal(false);

  protected readonly form = this.fb.group({
    dates: this.fb.array([this.dateControl()]),
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
    return this.fb.control('', { validators: Validators.required });
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

The messages are in one object keyed by the names the validators use, so a validator added later
gets its sentence in one place. `focusFirstProblem` finds the first invalid control by its position
and focuses the input with the matching id. It reads the controls rather than the page, because
the page is drawn after `submit` returns, so its classes still describe the moment before the click.

`--a11y` shows the form as a screen reader has it: each field's name, state and the description its
`aria-describedby` points at. An empty form, submitted:

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-add-session --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [invalid] [focused] (description: This is needed.)
  - paragraph
    - text: This is needed.
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes": 30
  - button "Add"
```

The date is `invalid`, has the focus, and is described by its message. The minutes field has no
message, because 30 is fine. Now a date, and too few minutes:

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-add-session --network --do 'fill Date 1 = 2026-10-26' --do 'fill Minutes = 2' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- fill Date 1 = 2026-10-26
-- fill Minutes = 2
-- click Add
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1": 2026-10-26
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes" [invalid] [focused]: 2 (description: At least 5 minutes.)
  - paragraph
    - text: At least 5 minutes.
  - button "Add"
```

The focus went past the date, which is valid now, to the minutes. The one request is the store's,
when the page loaded: no `POST` was sent.
