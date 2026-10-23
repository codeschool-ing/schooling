---
title: The imports list, and the error it prevents
version: 1
---

**A template can use another component only if the component that owns the template imports it.**
That is the whole rule, and the error when it is broken is one you will read many times, so this
section breaks it on purpose.

The planner's first screen is the week, from lesson 1's tree. Generate it:

```
ana@dev:~/planner$ npx ng generate component week
CREATE src/app/week/week.css (0 bytes)
CREATE src/app/week/week.spec.ts (517 bytes)
CREATE src/app/week/week.ts (178 bytes)
CREATE src/app/week/week.html (19 bytes)
```

Its template is a heading and the summary from the previous section:

```html
<!-- src/app/week/week.html -->
<h2>This week</h2>
<app-week-summary />
```

`<app-week-summary />` closes itself: a component tag with nothing inside can be written that way,
which plain HTML does not allow for its own elements. The root component shows the week under the
page's heading, so `App` imports `Week` and writes its tag:

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

The `title` signal `ng new` put in `App` is gone: nothing reads it. `Week` itself is as the CLI wrote
it, with `imports: []`. Build:

```
ana@dev:~/planner$ npx ng build
❯ Building...
✔ Building...
Application bundle generation failed. [3.220 seconds] - 2026-10-23T23:12:39.409Z

✘ [ERROR] NG8001: 'app-week-summary' is not a known element:
1. If 'app-week-summary' is an Angular component, then verify that it is included in the '@Component.imports' of this component.
2. If 'app-week-summary' is a Web Component then add 'CUSTOM_ELEMENTS_SCHEMA' to the '@Component.schemas' of this component to suppress this message. [plugin angular-compiler]

    src/app/week/week.html:3:0:
      3 │ <app-week-summary />
        ╵ ~~~~~~~~~~~~~~~~~~~~

  Error occurs in the template of component Week.

    src/app/week/week.ts:6:15:
      6 │   templateUrl: './week.html',
        ╵                ~~~~~~~~~~~~~
```

`NG8001` is the error's code, and the message says everything that matters: `app-week-summary` is not
a known element, in `week.html`, which belongs to `Week`. The second half of the message is about
custom elements that are not Angular components at all, and does not apply. **Angular checks every
tag in a template against the component's `imports`**, at build time, and refuses one it cannot
resolve, rather than drawing an empty unknown element and leaving you to wonder.

The fix is in the class that owns the template, not in `WeekSummary`:

```typescript
// src/app/week/week.ts
import { Component } from '@angular/core';
import { WeekSummary } from '../week-summary/week-summary';

@Component({
  selector: 'app-week',
  imports: [WeekSummary],
  templateUrl: './week.html',
  styleUrl: './week.css',
})
export class Week {}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | tail -3

Output location: /home/ana/planner/dist/planner
```

## What goes in the list

| put in `imports` | because the template uses it as |
|---|---|
| a component | an element: `<app-week-summary />` |
| a directive | an attribute: `routerLink`, in lesson 17 |
| a pipe | a `|` in an expression: `date`, in lesson 19 |
| an NgModule | all of the above at once, for libraries that still ship modules: the next sections |

What does not go there is anything the class uses in its own code, such as a service: a TypeScript
`import` at the top of the file is enough for that. The `imports` of the decorator are only for the
template, which TypeScript does not read.

Two lists, then, with the same word. The `import` lines at the top make a name available to the
file, and the `imports` of `@Component` make it available to the template. A component in the
second list has to be in the first as well, which is why your editor offers to add both.
