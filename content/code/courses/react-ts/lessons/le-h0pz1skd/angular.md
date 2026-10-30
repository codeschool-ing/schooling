---
title: Angular, a class and signals
version: 1
---

**Angular is the framework of lesson 1, the one that comes with everything**, and it has its own command
to create a project rather than a template for Vite. Two things about the version first. Angular 22,
the newest, asks for Node.js 22.22.3 or later, and this course runs 22.22.0, so the project is made with
Angular 21, the version before it. And the lab's environment sets `NG_CLI_ANALYTICS=false`, so the tool
does not stop to ask whether it may collect usage data; on your own computer it asks once, and either
answer is fine.

```
ana@dev:~$ npx --yes @angular/cli@21.2.28 new sessions-angular --defaults --skip-install --skip-git --ssr=false | tail -n 4
CREATE sessions-angular/src/app/app.html (20144 bytes)
CREATE sessions-angular/src/app/app.config.ts (313 bytes)
CREATE sessions-angular/src/app/app.routes.ts (77 bytes)
CREATE sessions-angular/public/favicon.ico (15086 bytes)
```

`--defaults` takes the default answer to every question, `--ssr=false` leaves out server rendering, and
`--skip-git` leaves the folder without a repository of its own. **`--skip-install`** is there because of
what happens next. The project's `package.json` asks for ranges, as `create-vite`'s did, and installing
them fails on this computer:

```
ana@dev:~/sessions-angular$ npm install 2>&1 | head -n 1
npm error Cannot read properties of null (reading 'edgesOut')
ana@dev:~/sessions-angular$ npm config set save-exact true --location=project && npm install @angular/common@21.2.25 @angular/compiler@21.2.25 @angular/core@21.2.25 @angular/forms@21.2.25 @angular/platform-browser@21.2.25 @angular/router@21.2.25 rxjs@7.8.2 tslib@2.8.1 @angular/build@21.2.28 @angular/cli@21.2.28 @angular/compiler-cli@21.2.25 jsdom@28.1.0 prettier@3.9.10 typescript@5.9.3 vitest@4.0.18 > /dev/null && grep -A 8 "\"devDependencies\"" package.json && ls src/app
  "devDependencies": {
    "@angular/build": "21.2.28",
    "@angular/cli": "21.2.28",
    "@angular/compiler-cli": "21.2.25",
    "jsdom": "28.1.0",
    "prettier": "3.9.10",
    "typescript": "5.9.3",
    "vitest": "4.0.18"
  }
app.config.ts
app.css
app.html
app.routes.ts
app.spec.ts
app.ts
```

**`Cannot read properties of null (reading 'edgesOut')`** is npm 10.9.4 failing while it works out peer
dependencies, and the package it fails on is Vitest: the template asks for any Vitest 4 from 4.0.8, npm
picks the newest 4.1, and that is the release it cannot resolve. Naming every version, with Vitest at
4.0.18, installs cleanly. It is lesson 1's lesson again from the other side: a range means the install
you get depends on the day you run it. Note also **TypeScript 5.9.3**, not the 6.0 of the other three
projects: Angular's build accepts 5.9 and nothing newer, so this is the newest it can use. `jsdom` and
`vitest` are for `ng test`, which this lesson does not run.

An Angular component is a **class with a decorator**. `src/app/sessions.ts`, written with semicolons, as
Angular's own files are:

```ts
import { Component, computed, signal } from '@angular/core';

type Session = { id: string; course: string; minutes: number; done: boolean };

@Component({
  selector: 'app-sessions',
  template: `
    <section>
      <h1>This week</h1>
      <p>{{ done() }} of {{ total() }} minutes done</p>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>
            <button [attr.aria-pressed]="s.done" (click)="toggle(s.id)">
              {{ s.course }} · {{ s.minutes }} min
            </button>
          </li>
        }
      </ul>
    </section>
  `,
})
export class Sessions {
  protected readonly sessions = signal<Session[]>([
    { id: 's1', course: 'Statistics', minutes: 40, done: true },
    { id: 's2', course: 'Python', minutes: 35, done: false },
    { id: 's3', course: 'Statistics', minutes: 45, done: false },
  ]);
  protected readonly done = computed(() =>
    this.sessions()
      .filter((s) => s.done)
      .reduce((sum, s) => sum + s.minutes, 0),
  );
  protected readonly total = computed(() =>
    this.sessions().reduce((sum, s) => sum + s.minutes, 0),
  );

  constructor() {
    console.log('Sessions ran');
  }

  protected toggle(id: string) {
    this.sessions.update((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)));
  }
}
```

- **`@Component`** tells Angular that the class is a component: `selector` is the tag that draws it, and
  `template` is its markup. Bigger components keep the template in an `.html` file beside the class,
  as the generated `app.ts` did.
- **`signal`** is a reactive value, read by calling it, `sessions()`, and **`computed`** is one worked
  out from others. They are the same idea as Vue's `ref` and Svelte's `$state`, in a third spelling.
- **`toggle` builds a new array**, like React's, through `update`. A signal decides whether it changed
  by comparing the old value with the new, so a session changed in place would not be noticed.
- In the template, **`@for (…; track s.id)`** repeats with a key, **`[attr.aria-pressed]`** binds an
  attribute, **`(click)`** listens for an event, and `{{ }}` puts a value into the text.
- **The `constructor` runs once**, when Angular creates the component. That is where the log goes.

`src/app/app.ts`, which the CLI generated with a router outlet and a long welcome page, is reduced to
drawing the component, and the files it used are removed:

```ts
import { Component } from '@angular/core';
import { Sessions } from './sessions';

@Component({
  selector: 'app-root',
  imports: [Sessions],
  template: '<app-sessions />',
})
export class App {}
```

Angular's build is its own, `ng build`, and its server is `ng serve`. With `--configuration production`,
`npm start` serves the same optimised code the build writes, on port 4200:

```
ana@dev:~/sessions-angular$ rm src/app/app.html src/app/app.css src/app/app.spec.ts && npm run build

> sessions-angular@0.0.0 build
> ng build

❯ Building...
✔ Building...
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-GFNTBLOI.js    | main          | 198.63 kB |                54.28 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes

                    | Initial total | 198.63 kB |                54.28 kB

Application bundle generation complete. [3.796 seconds] - 2026-10-24T02:47:09.086Z

Output location: /home/ana/sessions-angular/dist/sessions-angular

ana@dev:~/sessions-angular$ look http://localhost:4200/ --do 'click button Python · 35 min' --do 'click button Statistics · 45 min'
Sessions ran
-- click button Python · 35 min
-- click button Statistics · 45 min
- heading "This week" [level=1]
- paragraph: 120 of 120 minutes done
- list:
  - listitem:
    - button "Statistics · 40 min" [pressed]
  - listitem:
    - button "Python · 35 min" [pressed]
  - listitem:
    - button "Statistics · 45 min" [pressed]
```

**`Sessions ran` once**, like Vue and Svelte. A click changed a signal, the template read that signal,
so Angular checked that template again and changed the text and the attributes that were different.
There is no `zone.js` in the dependencies, which older Angular used to notice changes: since version 21,
a new project leaves it out, and learns that something changed from its signals and from the events its
templates listen to.
