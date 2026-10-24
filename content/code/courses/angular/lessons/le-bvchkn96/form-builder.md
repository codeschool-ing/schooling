---
title: FormBuilder, the shorter spelling
version: 1
---

**`FormBuilder` makes the same controls, groups and arrays with less to type.** Every control so far
was `new FormControl(value, { nonNullable: true })`; in a form of ten fields that is ten repetitions
of the option. `NonNullableFormBuilder` is a service that builds every control non-nullable, so the
option goes:

```typescript
// src/app/add-session/add-session.ts
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule } from '@angular/forms';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      <h3>Add a session</h3>
      <label for="date">Date</label>
      <input id="date" type="date" formControlName="date" />
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
      <button type="submit">Add</button>
      @if (error(); as message) {
        <p role="alert">{{ message }}</p>
      }
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
export class AddSession {
  readonly courseId = input.required<string>();
  private readonly store = inject(PlannerStore);
  private readonly fb = inject(NonNullableFormBuilder);
  protected readonly error = signal<string | null>(null);
  protected readonly form = this.fb.group({
    date: '',
    minutes: 30,
  });

  protected submit(): void {
    this.error.set(null);
    this.store.add({ courseId: this.courseId(), ...this.form.getRawValue() }).subscribe({
      next: () => this.form.reset(),
      error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),
    });
  }
}
```

`fb.group({ date: '', minutes: 30 })` makes a control of each plain value, and the group's type is
the same as before: `date` a string, `minutes` a number, neither nullable. The build finds no error,
which is the check that matters for a rewrite like this one:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'ERROR|bundle generation'
Application bundle generation complete. [2.620 seconds] - 2026-10-24T01:10:14.306Z
```

| written with `new` | written with the builder |
|---|---|
| `new FormControl('', { nonNullable: true })` | `fb.control('')`, or `''` inside a group |
| `new FormGroup({ ... })` | `fb.group({ ... })` |
| `new FormArray([ ... ])` | `fb.array([ ... ])` |

`FormBuilder` without the `NonNullable` makes nullable controls, as `new FormControl` does by
default, and `inject(FormBuilder).nonNullable` is the same as `NonNullableFormBuilder`. Code you read
will use all three spellings; they build the same objects.
