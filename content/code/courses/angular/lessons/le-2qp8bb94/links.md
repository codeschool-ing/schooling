---
title: Links the router follows
version: 1
---

**`routerLink` makes a link the router follows without reloading the page.** It is still an `<a>`
with an `href`, so it can be opened in a new tab, copied, and read out as a link by a screen
reader. A click on it changes the address and swaps the component in the outlet; nothing is fetched
again, and the store's data is still there.

Each course in the week becomes a link to its page. `['/courses', course().id]` builds the path from
its segments, which is safer than gluing strings when an id could contain a character a URL needs
escaped:

```typescript
// src/app/course-card/course-card.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Course } from '../planner';

@Component({
  selector: 'app-course-card',
  imports: [RouterLink],
  template: `<a class="name" [routerLink]="['/courses', course().id]">{{ course().name }}</a>: {{ minutes() }} minutes`,
  styles: `
    .name {
      font-weight: 600;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseCard {
  readonly course = input.required<Course>();
  readonly minutes = input(0);
}
```

And `App` gets a way back. `routerLinkActive` adds a class while the link's address is the current
one, `exact: true` so that `/` is not active on every page, and `ariaCurrentWhenActive` sets
`aria-current="page"`, which a screen reader announces as "current page":

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<nav aria-label="Planner">
  <a routerLink="/" routerLinkActive="current" [routerLinkActiveOptions]="{ exact: true }" ariaCurrentWhenActive="page">This week</a>
</nav>
<main>
  <router-outlet />
</main>
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```css
/* src/app/app.css */
nav {
  display: flex;
  gap: 1rem;
}
```

`--url` prints the address the page ended up at. A click on a course:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text main --do 'click JavaScript' --url
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click JavaScript
url: /courses/javascript
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
Add sessions
Date 1
Another date
Minutes
Add
```

And the navigation's HTML on the week, where its link is the current page:

```
ana@dev:~/planner$ look http://localhost:4200/ --html 'app-root nav'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<nav aria-label="Planner"><a routerlink="/" routerlinkactive="current" ariacurrentwhenactive="page" href="/" class="current" aria-current="page">This week</a></nav>
```

## The tests notice

The tests the CLI generated, and lesson 10's, have not been run since the router arrived:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|^ERROR|Tests '
ERROR ɵNotFound: NG0201: No provider found for `ActivatedRoute`. Source: DynamicTestModule. Find more at https://v21.angular.dev/errors/NG0201
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 3 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/app.spec.ts > App > should create the app
 FAIL  |planner| src/app/app.spec.ts > App > should render the heading
 FAIL  |planner| src/app/week/week.spec.ts > Week > counts the week that holds today
      Tests  3 failed | 2 passed (5)
```

`NG0201` again, lesson 10's error: `routerLink` injects `ActivatedRoute`, and a test builds its
components through an injector of its own, which nobody gave a router. `App` has a link, and so does
every `CourseCard` the week draws. `provideRouter([])` gives each test a router with no routes,
which is all a link needs to be drawn:

```typescript
// src/app/app.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
      providers: [provideRouter([])],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render the heading', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toBe('Study planner');
  });
});
```

```typescript
// src/app/week/week.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { TODAY } from '../today';
import { Week } from './week';

describe('Week', () => {
  it('counts the week that holds today', async () => {
    TestBed.configureTestingModule({
      imports: [Week],
      providers: [provideRouter([]), { provide: TODAY, useValue: new Date('2026-10-28T09:00:00') }],
    });
    const fixture = TestBed.createComponent(Week);
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2026-10-26 to 2026-11-01');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|^ERROR|Tests '
      Tests  5 passed (5)
```
