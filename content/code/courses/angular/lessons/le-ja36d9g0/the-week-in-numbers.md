---
title: The week, in numbers
version: 1
---

**Back to the planner, with what the bench taught.** The week's summary gets its two numbers from
lesson 1, 165 minutes planned and 90 done, and a progress bar drawn with a property binding. The
numbers are written into the class for now; lesson 6 computes them from the data.

```typescript
// src/app/week-summary/week-summary.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly planned = 165;
  protected readonly done = 90;
}
```

`readonly`, because nothing in the component should change them: the template reads them and nothing
writes them. Lesson 1 promised Angular code would put `protected` and `readonly` on almost every field
a template reads, and here is the first pair.

```html
<!-- src/app/week-summary/week-summary.html -->
<p>{{ planned }} minutes planned, {{ done }} done.</p>
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done" [max]="planned"></progress>
```

A `<progress>` element is the browser's own progress bar, with the role a screen reader announces as
one, and its label comes from the `<label>` beside it. The bench is no longer needed. Delete its folder,
and take it out of `App` again:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<app-week />
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
(nothing on the page matches main)
```

`look --a11y main` found no `main`, so it says so. The page has no landmark yet: the screen reader user
arriving here has no way to jump to the content, which is one of the first things an accessibility
check flags. Wrap the week in one:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
</main>
<router-outlet />
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
  - LabelText
    - text: Done this week
  - progressbar "Done this week": 90
```

The `<label>` became the progress bar's name, `Done this week`, and its value is 90, which a screen
reader announces against the maximum the binding set, 165. The tests still pass, and the planner is
committed:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Bindings: the week's numbers and its progress bar"
```
