---
title: Asking for a thing instead of building it
version: 1
---

**Dependency injection means a class says what it needs and something else hands it over.** The
class does not call `new` on its collaborators, and it does not reach for a global; it asks, and
an injector answers. Angular is built on this from the bottom up. Every `inject()` you have written
so far, `inject(DestroyRef)` in lesson 9 among them, was a question put to an injector.

The week screen shows why it matters. `Week` works out which week to count like this:

```typescript
private readonly week = weekOf(isoDay(new Date()));
```

`new Date()` is the computer's clock, read by the component itself. Nobody can hand `Week` a
different day: the transcripts in this course get one only because `look --today` changes the
browser's clock underneath it, and a test would have to do the same. A component that asked for
today, instead of reading it, could be given any day by whoever builds it. That is where this lesson
ends up, in its fourth section.

## A class that is asked for

Start with something smaller than a date: a class with one method, and a component that wants an
instance of it. The bench again:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component, Injectable, inject } from '@angular/core';\n\n@Injectable()\nexport class Greeter {\n  greet(name: string): string {\n    return `Hello, ${name}`;\n  }\n}", "note": "`@Injectable()` marks a class Angular may build and hand out. On its own it says nothing about where."},
 {"code": "@Component({\n  selector: 'app-bench',\n  template: '<p>{{ text }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  private readonly greeter = inject(Greeter);\n  protected readonly text = this.greeter.greet('Ana');\n}", "note": "The bench asks for a `Greeter` and uses it. It never writes `new Greeter()`."}
]}
```

It goes into `App` the way lesson 9's bench did:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

The stack trace of an Angular error runs to a dozen lines of the framework's own files, so
`grep -v` leaves them out, as it did in lesson 7:

```
ana@dev:~/planner$ look http://localhost:4200/ --text body | grep -v '^    at '
[vite] connecting...
[vite] connected.
[error] ERROR ɵNotFound: NG0201: No provider found for `_Greeter`. Source: Environment Injector. Find more at https://v21.angular.dev/errors/NG0201
[error] ɵNotFound: NG0201: No provider found for `_Greeter`. Source: Environment Injector. Find more at https://v21.angular.dev/errors/NG0201
Study planner
```

**NG0201 says nobody was told how to make a `Greeter`.** `@Injectable()` lets Angular build the
class, but no injector on the way up from the bench had been given it, so the question reached the
last one, which answers every question by failing. `_Greeter` is the build's own name for the
class. The error is printed twice, once by Angular's error handler and once by the `catch` at the end
of `main.ts`, because the application never finished starting. Only the heading made it to the page:
a component that cannot be built stops the view it sits in, and here that view was the whole
application.

## Where to find one

One argument fixes it. `providedIn: 'root'` tells Angular that the application's root injector
can make a `Greeter`, and makes it the first time somebody asks:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Greeter {
  greet(name: string): string {
    return `Hello, ${name}`;
  }
}

@Component({
  selector: 'app-bench',
  template: '<p>{{ text }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly greeter = inject(Greeter);
  protected readonly text = this.greeter.greet('Ana');
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Hello, Ana
```

The root injector makes **one** `Greeter` and hands the same one to everybody who asks, for as
long as the application runs. A class nobody asks for is never made, and the build leaves it out of
the bundle, which is why `providedIn: 'root'` is the form the CLI writes and the one to reach for
first.

## The older spelling

Code written before Angular 14 asks through the constructor's parameters instead, and you will
read a great deal of it:

```typescript
export class Bench {
  constructor(private readonly greeter: Greeter) {}
}
```

Angular reads the parameter's type and injects a `Greeter` there. It is the same question to the
same injector, and the two can be mixed in one class. `inject()` is what the CLI generates now,
and it has two advantages a parameter does not: it works in a plain field, and in a function that
is not a class at all, which the last section of this lesson uses.
