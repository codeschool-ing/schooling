---
title: Validation written in the template
version: 1
---

**In a template-driven form the validators are attributes.** `required` and `min="5"` on an input
with `ngModel` are directives that add `Validators.required` and `Validators.min(5)` to the control
`ngModel` made. A template reference, `#day="ngModel"`, gives the template that control, so the
template can ask whether it is invalid or touched; `#f="ngForm"` gives it the whole form.

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
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
export class Bench {
  protected readonly date = signal('');
  protected readonly minutes = signal(30);

  protected check(f: NgForm): void {
    console.log('submitted:', JSON.stringify(f.value), 'valid:', f.valid);
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Length in minutes = 2' --do 'click Check'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Length in minutes = 2
-- click Check
submitted: {"date":"","minutes":2} valid: false
Day

This is needed.

Length in minutes

At least 5 minutes.

Check
```

The same rules as lesson 15's form, with less code in the class, and every decision is in the
template: which validators, when a message shows, what is sent. For a form of two fields that is
pleasant to read. It is also where the trouble starts.
