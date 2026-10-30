---
title: resource, a signal that waits for something
version: 1
---

**`resource` turns something asynchronous, a request, a file, a timer, into signals: one for the
value, one for whether it is still loading, and one for the error if it failed.** Lesson 2 put the
planner's data in `public/courses.json` and promised that a signal that waits would read it. This
is that signal. Give the week's summary the data, and for now let it only count the sessions:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, resource } from '@angular/core';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({
    loader: async (): Promise<PlannerData> => (await fetch('/course.json')).json(),
  });
}
```

```html
<!-- src/app/week-summary/week-summary.html -->
@if (data.isLoading()) {
  <p>Loading the week…</p>
} @else if (data.error(); as error) {
  <p>The week could not be loaded: {{ error.message }}</p>
} @else if (data.value(); as value) {
  <p>{{ value.sessions.length }} sessions loaded.</p>
}
```

`PlannerData` is the shape of the whole file, one more interface in `src/app/planner.ts`:

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

export interface PlannerData {
  courses: Course[];
  sessions: Session[];
}
```

The `loader` is an `async` function, and `resource` calls it once the component exists and keeps its
result in signals. The template reads three of them: `isLoading()`, `error()` and `value()`, each
with parentheses, each a signal like the ones above. The value is `undefined` until the loader
finishes, so the last branch names it with `as`, the way lesson 5's `@if` did, and reads it already
known to be there.

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /course.json  404
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
The week could not be loaded: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

The address in the loader says `/course.json`, without the `s`. `--network` lists the requests the
page's code made, and the dev server answered that one `404`, with an error page in HTML. Then the
message: `.json()` tried to read HTML as JSON, threw, and `resource` caught the error and put it in
`error()`. **The template had a branch for it, so the page says something went wrong instead of going
blank**, which is the reason to write all three branches every time.

The message itself is misleading, though: it blames the JSON, and the real problem was the 404. That
is a property of `fetch`: **it only rejects when there is no answer at all**, and a 404 or a 500 is an
answer, so the loader carried on and parsed an error page. Check the status before reading the body:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, resource } from '@angular/core';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({
    loader: async (): Promise<PlannerData> => {
      const response = await fetch('/course.json');
      if (!response.ok) throw new Error(`${response.url} answered ${response.status}`);
      return response.json();
    },
  });
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
The week could not be loaded: http://localhost:4200/course.json answered 404
```

Now the page names the address and the status, which is the message you want on the day a real
server is down. Correct the address:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, resource } from '@angular/core';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly data = resource({
    loader: async (): Promise<PlannerData> => {
      const response = await fetch('/courses.json');
      if (!response.ok) throw new Error(`${response.url} answered ${response.status}`);
      return response.json();
    },
  });
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary --network
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /courses.json  200
6 sessions loaded.
```

Six sessions. Note what remains possible: `Promise<PlannerData>` is a promise TypeScript believed.
Nothing checked that the answer was a planner's data; the type is a claim about the server, written by
you. Lesson 12 comes back to that with `HttpClient`.

## What resource is, today

`resource` is marked **experimental** in Angular 21: its API can still change between versions,
which is the framework saying so in its own documentation. It is the way Angular is heading for
asynchronous data in signals, and lesson 12 has a version made for HTTP. The `fetch` in this loader is
the browser's own, which `javascript` lesson 16 used, and it is replaced in lesson 12.

A resource can also take **`params`**, a function reading signals: when they change, the loader runs
again with the new values, and the previous request is cancelled through the `abortSignal` the loader
receives. The planner needs that in lesson 17, when the course on screen comes from the address.
