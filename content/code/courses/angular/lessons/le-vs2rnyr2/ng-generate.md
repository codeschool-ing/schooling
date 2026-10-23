---
title: Generating instead of typing
version: 1
---

**`ng generate` writes the files of a new piece of the application, in the shape the project
already uses.** A component is four files with a decorator, an import and a selector that have to
agree with each other; typing them by hand is where a mismatch gets in. The planner's first new
component is the summary of the week, from lesson 1's tree.

Ask first what it would do. `--dry-run` prints the plan and writes nothing:

```
ana@dev:~/planner$ npx ng generate component week-summary --dry-run
CREATE src/app/week-summary/week-summary.css (0 bytes)
CREATE src/app/week-summary/week-summary.spec.ts (567 bytes)
CREATE src/app/week-summary/week-summary.ts (209 bytes)
CREATE src/app/week-summary/week-summary.html (27 bytes)

NOTE: The "--dry-run" option means no changes were made.
```

Then for real, and the class it wrote:

```
ana@dev:~/planner$ npx ng generate component week-summary
CREATE src/app/week-summary/week-summary.css (0 bytes)
CREATE src/app/week-summary/week-summary.spec.ts (567 bytes)
CREATE src/app/week-summary/week-summary.ts (209 bytes)
CREATE src/app/week-summary/week-summary.html (27 bytes)
ana@dev:~/planner$ cat src/app/week-summary/week-summary.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {}
```

Four things to notice, because every component you generate looks like this:

- **The name you typed, `week-summary`, became three names.** The folder and the files are
  `week-summary`, the class is `WeekSummary`, and the selector, the tag you write in a template to
  use the component, is `app-week-summary`. `app` is the prefix `ng new` chose, so a component of
  yours never collides with an HTML element or with another library's.
- **The files are named for what they are, without a type in the name.** Older projects, and most
  of the code you will open at work, have `week-summary.component.ts` and a class called
  `WeekSummaryComponent`. Angular changed its style guide in version 20, and `ng new` asks for the
  new one; `--file-name-style-guide=2016` would bring the old one back.
- **`imports: []`** is the list of other components the template may use. It is empty because the
  template uses none, and lesson 3 is about what goes there.
- **A test came with it**, `week-summary.spec.ts`, which checks that the component can be created.
  `--skip-tests` leaves it out; this course keeps them, and lesson 24 is about writing real ones.

Nothing uses `WeekSummary` yet, so the page has not changed. Lesson 4 puts it on the screen.

## What else it generates

`component` is one **schematic**, the CLI's word for a generator. The ones this course uses, each in
the lesson that first needs it:

| command | writes | lesson |
|---|---|---|
| `ng generate component NAME` | a component: class, template, styles, test | 3 to 9 |
| `ng generate service NAME` | a class marked `@Injectable` | 11 |
| `ng generate interceptor NAME` | a function that sees every HTTP request | 12 |
| `ng generate guard NAME` | a function the router asks before it navigates | 18 |
| `ng generate pipe NAME` | a function a template uses to format a value | 19 |
| `ng generate directive NAME` | behaviour you attach to an existing element | 20 |

Each has a short form, `ng g c`, `ng g s` and so on, and each accepts `--dry-run`, which is the
habit worth keeping: see what it will write before it writes it.
