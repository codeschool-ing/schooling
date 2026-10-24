---
title: Queries, reaching an element or a child
version: 1
---

**A query gives a component a signal holding an element or a child component from its own template.**
Most of the time data and events are enough, and a query is the exception: for the few things a
component must do to an element directly, such as moving the keyboard's focus to it. `viewChild` finds
something in the component's own template; `contentChild` finds something in the content projected
into it.

The bench gets a field and a button that puts the cursor in it:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, ElementRef, viewChild } from '@angular/core';

@Component({
  selector: 'app-bench',
  template: `
    <h2>Bench</h2>
    <label for="bench-note">Note</label>
    <input id="bench-note" #note />
    <button type="button" (click)="write()">Write a note</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly note = viewChild.required<ElementRef<HTMLInputElement>>('note');

  protected write(): void {
    this.note().nativeElement.focus();
  }
}
```

`viewChild.required<…>('note')` finds the element with the reference `#note` and returns a signal
holding an `ElementRef`, Angular's wrapper around the DOM element, whose `nativeElement` is the input
itself. `.required` promises it exists, so the signal is never `undefined`.

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-bench --do 'click Write a note'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Write a note
- heading "Bench" [level=2]
- LabelText
  - text: Note
- textbox "Note" [focused]
- button "Write a note"
```

The field is the one marked focused. For a sighted mouse user that is a convenience; for somebody on a
keyboard or a screen reader, it is the difference between being taken to the field and having to hunt
for it, and lessons 9 and 21 use the same move when a screen changes.

Like inputs and outputs, queries had a decorated form first, `@ViewChild('note') note!: ElementRef`,
filled in a lifecycle hook lesson 9 introduces, and `ng generate @angular/core:signal-queries-migration`
rewrites it.

## Clearing the bench, and the tests

Delete the bench and take it out of `App`:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error:|Tests '
ERROR RuntimeError: NG0950: Input "planned" is required but no value is available yet. Find more at https://v21.angular.dev/errors/NG0950
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/week-summary/week-summary.spec.ts > WeekSummary > should create
Error: NG0950: Input "planned" is required but no value is available yet. Find more at https://v21.angular.dev/errors/NG0950
      Tests  1 failed | 3 passed (4)
```

`WeekSummary`'s generated test creates the component and never sets its inputs, and a required input
read before anybody set it is an error, `NG0950`. A test is a parent like any other and has to provide
what the component requires. `setInput` does it, through the component's reference:

```typescript
// src/app/week-summary/week-summary.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { WeekSummary } from './week-summary';

describe('WeekSummary', () => {
  let component: WeekSummary;
  let fixture: ComponentFixture<WeekSummary>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [WeekSummary],
    }).compileComponents();

    fixture = TestBed.createComponent(WeekSummary);
    fixture.componentRef.setInput('planned', 165);
    fixture.componentRef.setInput('done', 90);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error:|Tests '
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Inputs, outputs and projection: the course page and its sessions"
```
