---
title: Lists with @for, and the track it insists on
version: 1
---

**`@for (item of list; track key) { … }` draws its block once per item, and `track` tells Angular
how to recognise an item it has already drawn.** The track is not optional: leave it out and the
template does not compile. The next section shows what it is for; this one puts the planner's courses
on the week screen.

The data's shapes, from lesson 1's `session.ts`, get a file of their own in the project, where every
component can import them:

```typescript
// src/app/planner.ts
export interface Course {
  id: string;
  name: string;
}

export interface Session {
  id: number;
  courseId: string;
  date: string;
  minutes: number;
  done: boolean;
}
```

The week lists the three courses. They are written into the class for now, the same three as
`public/courses.json`; lesson 6 reads the file instead:

```typescript
// src/app/week/week.ts
import { Component } from '@angular/core';
import { Course } from '../planner';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
})
export class Week {
  protected readonly courses: Course[] = [
    { id: 'html-css', name: 'HTML and CSS' },
    { id: 'javascript', name: 'JavaScript' },
    { id: 'git', name: 'Git' },
  ];
}
```

```html
<!-- src/app/week/week.html -->
<h2>This week</h2>
<app-week-summary />
<h3>Courses</h3>
<ul>
  @for (course of courses; track course.id) {
    <li>{{ course.name }}</li>
  } @empty {
    <li>No courses yet.</li>
  }
</ul>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
- main
  - heading "This week" [level=2]
  - paragraph
    - text: 165 minutes planned, 90 done.
  - paragraph
    - text: 75 minutes to go.
  - LabelText
    - text: Done this week
  - progressbar "Done this week": 90
  - heading "Courses" [level=3]
  - list
    - listitem [level=1]
      - ListMarker "• "
      - text: HTML and CSS
    - listitem [level=1]
      - ListMarker "• "
      - text: JavaScript
    - listitem [level=1]
      - ListMarker "• "
      - text: Git
```

A list of three items, and the screen reader is told it is a list with three. **`@empty`** is the
block drawn when the list has no items at all, which is the state every list is in on its first day
and the one most often forgotten.

## What @for knows about each item

Inside the block, besides the item, `@for` offers a few names about where the item is:

| name | is |
|---|---|
| `$index` | the item's position, from 0 |
| `$count` | how many items there are |
| `$first`, `$last` | whether this is the first or the last |
| `$even`, `$odd` | whether `$index` is even or odd |

`<li>{{ $index + 1 }} of {{ $count }}: {{ course.name }}</li>` would number the courses. They are
handy and you will see them, and one of them, `$index`, is the wrong thing to track by, which is the
next section.
