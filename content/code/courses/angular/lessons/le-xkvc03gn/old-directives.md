---
title: The old directives, and the migration that removes them
version: 1
---

**Before Angular 17, a template's conditions and loops were directives written as attributes:
`*ngIf`, `*ngFor` and `[ngSwitch]`.** They are still in most of the Angular code in production, they
are deprecated since Angular 20, and the CLI ships a migration that rewrites them into the blocks this
lesson taught. This section writes them on the bench, the way older code does, and runs it.

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';
import { NgFor, NgIf } from '@angular/common';
import { Course } from '../planner';

@Component({
  selector: 'app-bench',
  imports: [NgIf, NgFor],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected courses: Course[] = [
    { id: 'html-css', name: 'HTML and CSS' },
    { id: 'javascript', name: 'JavaScript' },
    { id: 'git', name: 'Git' },
  ];

  protected byId(index: number, course: Course): string {
    return course.id;
  }
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p *ngIf="courses.length > 0; else none">{{ courses.length }} courses</p>
<ng-template #none><p>No courses.</p></ng-template>
<ul>
  <li *ngFor="let course of courses; trackBy: byId; let i = index">{{ i + 1 }}. {{ course.name }}</li>
</ul>
```

What to recognise:

- **They are directives, so they are imported**: `NgIf` and `NgFor` from `@angular/common`, or
  `CommonModule`, which carried them all. The blocks need no import.
- **The `*` is shorthand.** `*ngIf` wraps its element in an `<ng-template>`, an inert piece of
  template that the directive draws or does not. The `else` branch has to be such a template, named
  with `#none`, which is why the old syntax scatters one condition across two places.
- **`trackBy` takes a function**, not an expression, and it was optional, so most old code has none.
- **`let i = index`** is the old spelling of `$index`.

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

3 courses

1. HTML and CSS
2. JavaScript
3. Git
```

It works, and it draws the same thing the blocks would. Commit first, so that the migration's edits
are the only thing in the diff, then run it:

```
ana@dev:~/planner$ git add -A && git commit -q -m "The bench, the old way"
```

```
ana@dev:~/planner$ npx ng generate @angular/core:control-flow
UPDATE src/app/bench/bench.html (274 bytes)
UPDATE src/app/bench/bench.ts (493 bytes)
```

```
ana@dev:~/planner$ git diff
diff --git a/src/app/bench/bench.html b/src/app/bench/bench.html
index 01049d3..449feb7 100644
--- a/src/app/bench/bench.html
+++ b/src/app/bench/bench.html
@@ -1,7 +1,12 @@
 <!-- src/app/bench/bench.html -->
 <h2>Bench</h2>
-<p *ngIf="courses.length > 0; else none">{{ courses.length }} courses</p>
-<ng-template #none><p>No courses.</p></ng-template>
+@if (courses.length > 0) {
+  <p>{{ courses.length }} courses</p>
+} @else {
+  <p>No courses.</p>
+}
 <ul>
-  <li *ngFor="let course of courses; trackBy: byId; let i = index">{{ i + 1 }}. {{ course.name }}</li>
+  @for (course of courses; track byId(i, course); let i = $index) {
+    <li>{{ i + 1 }}. {{ course.name }}</li>
+  }
 </ul>
diff --git a/src/app/bench/bench.ts b/src/app/bench/bench.ts
index 303eaf5..e6ff04c 100644
--- a/src/app/bench/bench.ts
+++ b/src/app/bench/bench.ts
@@ -1,11 +1,11 @@
 // src/app/bench/bench.ts
 import { Component } from '@angular/core';
-import { NgFor, NgIf } from '@angular/common';
+
 import { Course } from '../planner';
 
 @Component({
   selector: 'app-bench',
-  imports: [NgIf, NgFor],
+  imports: [],
   templateUrl: './bench.html',
   styleUrl: './bench.css',
 })
```

The `*ngIf` and its separate `<ng-template>` became one `@if` with an `@else`, and the loop became an
`@for`. Look at its track: `track byId(i, course)` calls the old `trackBy` function with the position
and the item, and `let i = $index` keeps the old name `i` for the position. It is correct, and it is
not what anybody would write today: `track course.id` says the same thing without a method. The
imports of `NgIf` and `NgFor` went, leaving an empty `imports` and a blank line where the import was.
A migration preserves behaviour; the tidying, as in lesson 3, is yours.

## Clearing the bench

The bench has served this lesson. Delete it, take it out of `App` again, and commit the planner:

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
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Control flow: the course list, and what is left this week"
```
