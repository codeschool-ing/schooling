---
title: A component, through what it shows
version: 1
---

**A component test builds the component with `TestBed`, gives it what it needs, and checks the
page it draws.** `CourseSessions` is a good subject: it filters the store's sessions to one course,
sorts them by date, and hides the done ones when asked. Each of those is a rule a person reading the
page would notice breaking, so the test reads the page:

```schooling-example
{"language": "typescript", "file": "src/app/course-sessions/course-sessions.spec.ts", "parts": [
 {"code": "// src/app/course-sessions/course-sessions.spec.ts\nimport { provideHttpClient } from '@angular/common/http';\nimport { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';\nimport { TestBed } from '@angular/core/testing';\nimport { PlannerData } from '../planner';\nimport { CourseSessions } from './course-sessions';\n"},
 {"code": "const planner: PlannerData = {\n  courses: [{ id: 'git', name: 'Git' }],\n  sessions: [\n    { id: 3, courseId: 'git', date: '2026-10-27', minutes: 40, done: false },\n    { id: 1, courseId: 'git', date: '2026-10-19', minutes: 30, done: true },\n    { id: 2, courseId: 'html-css', date: '2026-10-20', minutes: 60, done: false },\n  ],\n};\n", "note": "Three sessions, out of order, one of them another course's: the component has to choose and sort, and the data is shaped so a mistake in either shows."},
 {"code": "describe('CourseSessions', () => {\n  beforeEach(() => {\n    localStorage.clear();\n    TestBed.configureTestingModule({\n      imports: [CourseSessions],\n      providers: [provideHttpClient(), provideHttpClientTesting()],\n    });\n  });\n", "note": "`imports` takes the component under test, standalone as it is. Its own imports, `MatCheckbox` and `SessionList` and the rest, come with it, real: this is a test of the component as the page uses it, not of the component alone. `localStorage.clear()` because `Preferences` keeps what one test set for the next."},
 {"code": "  async function render() {\n    const fixture = TestBed.createComponent(CourseSessions);\n    fixture.componentRef.setInput('courseId', 'git');\n    TestBed.tick();\n    TestBed.inject(HttpTestingController).expectOne('/api/planner').flush(planner);\n    await fixture.whenStable();\n    return fixture;\n  }\n", "note": "`setInput` sets a signal input, as a parent's template would. Then the request, answered as in the last section, and `whenStable()` until everything that depends on it has been drawn."},
 {"code": "  it(\"lists the course's sessions, oldest first\", async () => {\n    const fixture = await render();\n    const rows = [...(fixture.nativeElement as HTMLElement).querySelectorAll('li')];\n    expect(rows.map((li) => li.textContent?.trim())).toEqual(['Mon 19 Oct, 30 minutes', 'Tue 27 Oct, 40 minutes']);\n  });\n\n});", "note": "The test reads the page, not the component's fields: the text of each row, as a person would. That makes it pass for any implementation that shows the right rows, and fail for any that does not."}
]}

```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*course-sessions|Tests '
 ✓ |planner| src/app/course-sessions/course-sessions.spec.ts (1 test) 163ms
      Tests  20 passed (20)
```

The test does not provide a fake `PlannerStore`. It could, with
`{ provide: PlannerStore, useValue: ... }`, and some teams do that for every component. But the
store is part of what the component's page depends on, and with the HTTP layer faked underneath it,
the real store costs nothing and catches more: a test against a hand-written fake checks the
component against the fake, which agrees with whatever its author believed. Replace a dependency
when the real one is slow, needs a network, or makes a test depend on something it is not about.

## The placeholder, made to say something

`week-summary.spec.ts` was created with the component in lesson 2 and has only ever asked whether
the component exists. The component's whole job is two sentences:

```typescript
// src/app/week-summary/week-summary.spec.ts
import { TestBed } from '@angular/core/testing';
import { WeekSummary } from './week-summary';

describe('WeekSummary', () => {
  it('says what is planned, what is done and what is left', async () => {
    const fixture = TestBed.createComponent(WeekSummary);
    fixture.componentRef.setInput('planned', 165);
    fixture.componentRef.setInput('done', 90);
    await fixture.whenStable();

    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2 hours 45 minutes planned, 1 hour 30 minutes done.');
    expect(text).toContain('1 hour 15 minutes to go.');
  });
});
```

No `configureTestingModule` at all: a standalone component with no dependencies can be created
directly. A component is not only its class, so "should create" proves less than it seems: it
passes for a template that shows the wrong numbers.

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*week-summary|Tests '
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 24ms
      Tests  20 passed (20)
```
