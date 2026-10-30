---
title: What to write today, and how old code gets here
version: 1
---

**For new code the answer is short: state in signals, OnPush on every component, and no zone.js.**
Each of the three makes the next one safe. Signals mark exactly what changed, OnPush lets Angular skip
everything else, and without zone.js nothing walks the tree because a mouse moved.

## OnPush on the planner

Every component the planner has reads its changing state from signals already, so marking them OnPush
changes nothing on the page and lets Angular skip each one when nothing it reads has changed. The bench
has done its job; delete it, and restore `App` with OnPush added:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

`Week` and `WeekSummary` get the same line, and their classes are otherwise as lesson 6 left them:

```typescript
// src/app/week/week.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Week {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
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

```typescript
// src/app/week-summary/week-summary.ts
import { ChangeDetectionStrategy, Component, computed, resource } from '@angular/core';
import { isoDay, loadPlanner, totals, weekOf } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WeekSummary {
  protected readonly data = resource({ loader: loadPlanner });
  private readonly week = weekOf(isoDay(new Date()));
  protected readonly totals = computed(() => totals(this.data.value()?.sessions ?? [], this.week));
}
```

And so that every component generated from now on starts that way, tell the CLI once:

```
ana@dev:~/planner$ npx ng config projects.planner.schematics.@schematics/angular:component.changeDetection OnPush
```

`ng config` writes into `angular.json`, under the project's `schematics`, the default for an option of
`ng generate component`. The next component lesson 8 generates comes with OnPush already in its
decorator.

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

The same week as lesson 6 ended with. Tests, and a commit:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Change detection: OnPush everywhere, no zone.js"
```

## An old application, made zoneless

The application you will meet at work has zone.js, few signals and a mix of OnPush and default
components. The move is done in this order, each step shippable on its own:

1. **Make components OnPush, one at a time**, and fix what goes stale: a field set asynchronously
   becomes a signal, or gets a `markForCheck()` for now. This is the slow step, and it is valuable
   even if the next ones never happen.
2. **Replace `provideZoneChangeDetection` with `provideZonelessChangeDetection()`**, which in
   Angular 21 is also what leaving both out means, and remove `zone.js` from `main.ts` or from
   `polyfills` in `angular.json`, and from `package.json`.
3. **Run every test and look at every screen.** Anything still stale was relying on zone.js and was
   missed in step 1.

Angular's documentation calls zoneless stable since version 20.2, and new projects have been zoneless
by default since 21. The zone.js code in the world will outlive this course; reading it is the skill,
and knowing which line of the previous sections it depends on is how you fix it.
