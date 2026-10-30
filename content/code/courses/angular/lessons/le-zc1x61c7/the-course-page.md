---
title: The second screen, given its course by an input
version: 1
---

**The planner's second screen shows one course and its sessions, and which course is an input.** Until
lesson 17 gives each screen an address, both screens sit on one page, and the course page is told
which course to show the same way the summary was told its numbers: by its parent, through an input.
In lesson 17 the router sets that same input from the address, and nothing in the page changes.

Two components, generated:

```
ana@dev:~/planner$ npx ng generate component course-page --skip-tests
CREATE src/app/course-page/course-page.css (0 bytes)
CREATE src/app/course-page/course-page.ts (281 bytes)
CREATE src/app/course-page/course-page.html (26 bytes)
```

```
ana@dev:~/planner$ npx ng generate component session-list --inline-template --inline-style --skip-tests
CREATE src/app/session-list/session-list.ts (289 bytes)
```

## The list of sessions

`SessionList` draws the sessions it is given, and knows nothing else:

```typescript
// src/app/session-list/session-list.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { Session } from '../planner';

@Component({
  selector: 'app-session-list',
  imports: [],
  template: `
    <ul>
      @for (session of sessions(); track session.id) {
        <li>{{ session.date }}, {{ session.minutes }} minutes{{ session.done ? ', done' : '' }}</li>
      } @empty {
        <li>No sessions yet.</li>
      }
    </ul>
  `,
  styles: ``,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionList {
  readonly sessions = input.required<Session[]>();
}
```

## The page

`CoursePage` loads the data, finds its course, and picks that course's sessions, sorted by date:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, input, resource } from '@angular/core';
import { loadPlanner } from '../planner';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly data = resource({ loader: loadPlanner });
  protected readonly course = computed(() =>
    this.data.value()?.courses.find((c) => c.id === this.courseId()),
  );
  protected readonly sessions = computed(() =>
    (this.data.value()?.sessions ?? [])
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

`course` and `sessions` read the input like any other signal, so they follow it: give the page another
`courseId` and both recompute. That is what lets lesson 17's router drive this page without a change
to it. `filter` builds a new array before `sort` reorders it, so the array in the resource is never
changed in place, as lesson 6 required.

```html
<!-- src/app/course-page/course-page.html -->
@if (data.isLoading()) {
  <p>Loading the course…</p>
} @else if (data.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <app-session-list [sessions]="sessions()" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

**The error branch has to come before anything reads the value.** In the error state, a resource's
`value()` does not answer `undefined`: it throws, and the `course()` that reads it would throw with it,
taking the page down. Checking `error()` first means `course()` is only read when there is a value to
read. The last branch matters from lesson 17 on, when the course comes from an address somebody may have
typed wrong.

## Both screens, for now

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
</main>
<router-outlet />
```

`courseId="javascript"`, without brackets, passes the text `javascript`. Brackets would read it as an
expression, a field called `javascript`, which does not exist.

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
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-course-page
[vite] connecting...
[vite] connected.
Angular is running in development mode.
JavaScript
2026-10-13, 45 minutes, done
2026-10-20, 60 minutes, done
2026-10-24, 50 minutes
```

JavaScript's three sessions, in date order. The page loads the file again, a second copy, for the
reason lesson 6 gave and lesson 11 removes; the next section shows what that second copy costs.
