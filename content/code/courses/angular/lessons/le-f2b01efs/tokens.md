---
title: Tokens for what is not a class
version: 1
---

**A class is its own token, but most of what a program needs is not a class: a date, a URL, a
number of minutes.** `inject(Date)` would ask for the `Date` class itself, which is the wrong
question, and two different strings cannot both be the type `string`. `InjectionToken` makes a
token out of nothing: an object whose only job is to be asked for, carrying the type of what it
stands for.

Today is the one the planner needs. A file of its own, since more than one component will ask:

```schooling-example
{"language": "typescript", "file": "src/app/today.ts", "parts": [
 {"code": "import { InjectionToken } from '@angular/core';\n\nexport const TODAY = new InjectionToken<Date>('TODAY', {", "note": "The type argument is what `inject(TODAY)` returns. The string is a description, shown in error messages and nowhere else."},
 {"code": "  providedIn: 'root',\n  factory: () => new Date(),\n});", "note": "`providedIn` and `factory` give the token a default recipe, as `providedIn: 'root'` does for a class: nobody has to list it anywhere."}
]}
```

The factory is called once, the first time somebody asks, and its answer is kept. So `TODAY` is the
moment the application first needed it, not a clock: a planner left open from Sunday to Monday
still counts the old week. That is the behaviour `new Date()` in a field had already, and the next lessons
keep it.

## The week asks for it

`Week` changes in one line, and `week` becomes `protected` so the template can show the range it
counts:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, inject, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { CourseCard } from '../course-card/course-card';
import { Panel } from '../panel/panel';
import { TODAY } from '../today';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [CourseCard, Panel, WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Week {
  protected readonly data = resource({ loader: loadPlanner });
  protected readonly week = weekOf(isoDay(inject(TODAY)));
  protected readonly totals = computed(() => totals(this.data.value()?.sessions ?? [], this.week));
  protected readonly rows = computed(() => {
    const data = this.data.value();
    if (!data) return [];
    return data.courses.map((course) => ({
      course,
      minutes: totals(data.sessions.filter((s) => s.courseId === course.id), this.week).planned,
    }));
  });
}
```

```html
<!-- src/app/week/week.html -->
<app-panel>
  <h2>This week</h2>
  <p>{{ week.start }} to {{ week.end }}</p>
  @if (data.isLoading()) {
    <p>Loading the week…</p>
  } @else if (data.error(); as error) {
    <p>The week could not be loaded: {{ error.message }}</p>
  } @else {
    <app-week-summary [planned]="totals().planned" [done]="totals().done" />
    <h3>Courses</h3>
    <ul>
      @for (row of rows(); track row.course.id) {
        <li><app-course-card [course]="row.course" [minutes]="row.minutes" /></li>
      } @empty {
        <li>No courses yet.</li>
      }
    </ul>
  }
</app-panel>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

Nothing a person can see changed, apart from the new line: the factory still calls `new Date()`,
and `--today` still sets the browser's clock under it. Lesson 19 writes those dates the way a person
would. What changed is who decides, and a test shows it.

## A test that names its day

The test the CLI generated for `Week` only checks that it can be made. Replace it with one that
checks the range, for Wednesday, 28 October, the week after the transcripts' own:

```typescript
// src/app/week/week.spec.ts
import { TestBed } from '@angular/core/testing';
import { Week } from './week';

describe('Week', () => {
  it('counts the week that holds today', async () => {
    TestBed.configureTestingModule({ imports: [Week] });
    const fixture = TestBed.createComponent(Week);
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2026-10-26 to 2026-11-01');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/week/week.spec.ts > Week > counts the week that holds today
AssertionError: expected 'This week2026-10-19 to 2026-10-25The …' to contain '2026-10-26 to 2026-11-01'
      Tests  1 failed | 3 passed (4)
```

It failed, and it would pass only during that one week. The test has no way to say which day it
means: the component reads it, and the clock is whatever the computer says. `TestBed` builds the
component through an injector of its own, and `providers` in its configuration go into it. One
`useValue` names the day:

```typescript
// src/app/week/week.spec.ts
import { TestBed } from '@angular/core/testing';
import { TODAY } from '../today';
import { Week } from './week';

describe('Week', () => {
  it('counts the week that holds today', async () => {
    TestBed.configureTestingModule({
      imports: [Week],
      providers: [{ provide: TODAY, useValue: new Date('2026-10-28T09:00:00') }],
    });
    const fixture = TestBed.createComponent(Week);
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2026-10-26 to 2026-11-01');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
      Tests  4 passed (4)
```

**The provider in the test wins over the token's factory**, as `useClass` won over `providedIn` in
the last section, and the test now passes on any day it is run. The test never loads the data,
because jsdom has no server to fetch `/courses.json` from, so it checks only what does not depend
on it; lesson 24 tests the totals as well, with a fake server in place of the real one.
