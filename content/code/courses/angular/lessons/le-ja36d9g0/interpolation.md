---
title: Interpolation, and a bench to try things on
version: 1
---

**A template is HTML with holes in it, and `{{ }}` is the simplest hole: Angular evaluates the
expression inside, turns the result into text, and puts the text there.** This lesson is about the
four ways a template and its class talk to each other, and it needs somewhere to try them that is not
the planner, so the first thing is a bench: a component that exists only for this lesson.

```
ana@dev:~/planner$ npx ng generate component bench --skip-tests
CREATE src/app/bench/bench.css (0 bytes)
CREATE src/app/bench/bench.ts (182 bytes)
CREATE src/app/bench/bench.html (20 bytes)
```

`--skip-tests`, because the bench is deleted at the end of the lesson and so would its test be. Put
it under the week, in `App`:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<app-week />
<app-bench />
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';
import { Bench } from './bench/bench';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

## Expressions in the holes

The bench's class holds a few values of different shapes:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-bench',
  imports: [],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected minutes = 45;
  protected course = { name: 'Git', sessions: 2 };
  protected note = '<b>bold?</b>';
  protected nothing: { name: string } | null = null;

  protected hours(m: number): string {
    return (m / 60).toFixed(2);
  }
}
```

and its template reads them:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p>{{ minutes }} minutes is {{ hours(minutes) }} hours.</p>
<p>{{ course.name }}: {{ course.sessions }} sessions, {{ course.sessions * minutes }} minutes.</p>
<p>{{ note }}</p>
<p>{{ nothing?.name ?? 'no name' }}</p>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

45 minutes is 0.75 hours.

Git: 2 sessions, 90 minutes.

<b>bold?</b>

no name
```

Each line shows one thing an expression may do:

- **read a field**, `minutes`, and **call a method**, `hours(minutes)`. The fields are `protected`:
  the template may read them, and code outside the class may not, which is the access a template
  needs and no more;
- **follow a property** and **do arithmetic**, `course.sessions * minutes`;
- **stay text**. `note` holds the characters of a `<b>` tag, and the page shows those characters, not
  bold text. Interpolation always produces text, and the browser is told to treat it as text, so a
  value that came from a user cannot turn into markup on the page. That is the defence against the
  attack `front-quality` calls cross-site scripting, built into the syntax;
- **cope with nothing**: `?.` stops at a `null` instead of throwing, and `??` supplies the fallback,
  both as in JavaScript.

## What an expression may not do

A template expression is a small subset of JavaScript on purpose. It may not assign (`minutes = 0`),
create objects with `new`, use `++`, or reach globals such as `window` and `console`: it sees the
component and nothing else. The one exception, assignment, is allowed in an event binding, two
sections on, because responding to an event is when changing something is the point.

A method called in a template is called every time Angular checks the template, which can be many
times a second. `hours()` is cheap, so it does not matter here; lesson 6 shows the tool for a value
that costs something to compute, and lesson 19 the one for formatting.
