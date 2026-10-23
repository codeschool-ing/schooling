---
title: Running the tests
version: 1
---

**`ng test` builds the tests and runs them with Vitest, in a browser imitation called jsdom, with no
window and no server.** Angular 21 projects use Vitest by default; older projects use Karma and a
real browser, and lesson 24 says what changed. Run it once, now, with `--watch=false` so it stops
when it is done:

```
ana@dev:~/planner$ npx ng test --watch=false
❯ Building...
✔ Building...
Initial chunk files                   | Names                              |  Raw size
chunk-CGZBV6BD.js                     | -                                  |   4.07 kB | 
spec-app-app.js                       | spec-app-app                       |   2.04 kB | 
spec-app-week-summary-week-summary.js | spec-app-week-summary-week-summary |   1.76 kB | 
init-testbed.js                       | init-testbed                       |   1.21 kB | 
vitest-mock-patch.js                  | vitest-mock-patch                  | 974 bytes | 
styles.css                            | styles                             |  56 bytes | 

                                      | Initial total                      |  10.11 kB

Application bundle generation complete. [1.506 seconds] - 2026-10-23T22:44:15.887Z


 RUN  v4.1.12 /home/ana/planner

 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 41ms
 ❯ |planner| src/app/app.spec.ts (2 tests | 1 failed) 49ms
     ✓ should create the app 34ms
     × should render title 13ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  |planner| src/app/app.spec.ts > App > should render title
AssertionError: expected 'Study planner' to contain 'Hello, planner'

Expected: "Hello, planner"
Received: "Study planner"

 ❯ src/app/app.spec.ts:21:55
     19|     await fixture.whenStable();
     20|     const compiled = fixture.nativeElement as HTMLElement;
     21|     expect(compiled.querySelector('h1')?.textContent).toContain('Hello…
       |                                                       ^
     22|   });
     23| });

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed | 1 passed (2)
      Tests  1 failed | 2 passed (3)
   Start at  19:44:16
   Duration  995ms (transform 119ms, setup 542ms, import 107ms, tests 90ms, environment 946ms)
```

One test failed, and it is right to. The test `ng new` wrote checks that the page's heading says
`Hello, planner`, and the previous section changed the heading. Read the report from the top: the
file and the test that failed, then `AssertionError` and the two values side by side, `Expected`
and `Received`, then the line of the test with a caret under the place it stopped. That order is the
same in every failure Vitest reports, and it is worth learning to read it fast.

The file the CLI wrote, all of it:

```
ana@dev:~/planner$ cat src/app/app.spec.ts
import { TestBed } from '@angular/core/testing';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render title', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Hello, planner');
  });
});
```

`describe` names a group of tests and `it` names one. `TestBed` is Angular's way of building a
component the way the application would, outside the application, and `fixture.nativeElement` is the
DOM it drew. Lesson 24 is the whole story; what matters now is the last line of the second test. Make
it expect the heading the page has now:

```typescript
// src/app/app.spec.ts
import { TestBed } from '@angular/core/testing';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
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

`toBe` is stricter than `toContain`: the heading must be exactly that, not merely include it.

```
ana@dev:~/planner$ npx ng test --watch=false
❯ Building...
✔ Building...
Initial chunk files                   | Names                              |  Raw size
chunk-CGZBV6BD.js                     | -                                  |   4.07 kB | 
spec-app-app.js                       | spec-app-app                       |   2.04 kB | 
spec-app-week-summary-week-summary.js | spec-app-week-summary-week-summary |   1.76 kB | 
init-testbed.js                       | init-testbed                       |   1.21 kB | 
vitest-mock-patch.js                  | vitest-mock-patch                  | 974 bytes | 
styles.css                            | styles                             |  56 bytes | 

                                      | Initial total                      |  10.11 kB

Application bundle generation complete. [1.399 seconds] - 2026-10-23T22:44:19.398Z


 RUN  v4.1.12 /home/ana/planner

 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 37ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 45ms

 Test Files  2 passed (2)
      Tests  3 passed (3)
   Start at  19:44:19
   Duration  982ms (transform 106ms, setup 515ms, import 95ms, tests 82ms, environment 955ms)
```

Three tests in two files: the two in `app.spec.ts`, and the one that came with `WeekSummary`.

Without `--watch=false`, `ng test` behaves like `ng serve`: it runs the tests, keeps the terminal,
and runs the affected ones again every time you save. That is how you will run it while you work; the
transcripts use `--watch=false` because a lesson needs the command to finish.
