---
title: The store, against a fake server
version: 1
---

**A service that talks to a server is tested with a fake one: `HttpTestingController` stands where
the network would be, and the test decides what each request is answered with.** Lesson 10 said
this lesson would test the totals this way. Nothing leaves the test, every answer is written in it,
and the store cannot tell the difference. The CLI's placeholder in `planner-store.spec.ts` gives way
to two tests that say something:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.spec.ts", "parts": [
 {"code": "// src/app/planner-store.spec.ts\nimport { provideHttpClient } from '@angular/common/http';\nimport { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';\nimport { ApplicationRef } from '@angular/core';\nimport { TestBed } from '@angular/core/testing';\nimport { PlannerData } from './planner';\nimport { PlannerStore } from './planner-store';\nimport { TODAY } from './today';\n"},
 {"code": "const planner: PlannerData = {\n  courses: [{ id: 'git', name: 'Git' }],\n  sessions: [\n    { id: 1, courseId: 'git', date: '2026-10-19', minutes: 30, done: true },\n    { id: 2, courseId: 'git', date: '2026-10-24', minutes: 50, done: false },\n    { id: 3, courseId: 'git', date: '2026-10-27', minutes: 40, done: false },\n  ],\n};\n", "note": "The planner, as the fake server will send it: three sessions of one course, two in the week of 23 October."},
 {"code": "describe('PlannerStore', () => {\n  let store: PlannerStore;\n  let server: HttpTestingController;\n\n  beforeEach(() => {\n    TestBed.configureTestingModule({\n      providers: [\n        provideHttpClient(),\n        provideHttpClientTesting(),\n        { provide: TODAY, useValue: new Date('2026-10-23T09:00:00') },\n      ],\n    });\n    store = TestBed.inject(PlannerStore);\n    server = TestBed.inject(HttpTestingController);\n  });\n", "note": "Two providers make `HttpClient` real and its backend fake: `provideHttpClient()`, then `provideHttpClientTesting()`, which must come after it. `TODAY` is fixed, as lesson 10 made possible, so the week does not depend on when the test runs."},
 {"code": "  afterEach(() => server.verify());\n", "note": "After each test, `verify()` fails if a request was made that the test never answered: a request nobody expected is a finding too."},
 {"code": "  async function load(): Promise<void> {\n    TestBed.tick();\n    server.expectOne('/api/planner').flush(planner);\n    await TestBed.inject(ApplicationRef).whenStable();\n  }\n", "note": "`TestBed.tick()` runs what Angular would run on its own in an application, and the resource sends its request then. `expectOne` finds that request, or fails; `flush` answers it. `whenStable()` waits for the resource to take the answer in."},
 {"code": "  it('totals the week from what the server sent', async () => {\n    await load();\n    expect(store.weekTotals()).toEqual({ planned: 80, done: 30 });\n  });\n", "note": "The first test reads what the screens read, `weekTotals()`: 30 + 50 planned, 30 done."},
 {"code": "  it('puts a session back when the server refuses the change', async () => {\n    await load();\n    store.toggle(2, true);\n    expect(store.weekTotals().done).toBe(80);\n\n    server\n      .expectOne({ method: 'PATCH', url: '/api/sessions/2' })\n      .flush({ error: 'done must be true or false' }, { status: 400, statusText: 'Bad Request' });\n\n    expect(store.weekTotals().done).toBe(30);\n    expect(store.saveError()).toBe('Session 2 was not saved: done must be true or false');\n  });\n});", "note": "The second ticks a session, checks the optimistic change, and answers the `PATCH` with the `400` the real API sends for a bad body. The store has to put the session back and say why."}
]}

```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*planner-store|Tests '
 ✓ |planner| src/app/planner-store.spec.ts (2 tests) 24ms
      Tests  19 passed (19)
```

## Why `TestBed.tick()`

The line is easy to leave out, because nothing in the test seems to need it. Take it out, and:

```
ana@dev:~/planner$ sed -i 's|^    TestBed.tick();|    // TestBed.tick();|' src/app/planner-store.spec.ts
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error|Tests '
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 2 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/planner-store.spec.ts > PlannerStore > totals the week from what the server sent
Error: Expected one matching request for criteria "Match URL: /api/planner", found none.
 FAIL  |planner| src/app/planner-store.spec.ts > PlannerStore > puts a session back when the server refuses the change
Error: Expected one matching request for criteria "Match URL: /api/planner", found none.
      Tests  2 failed | 17 passed (19)
```

"found none". A resource does not send its request when it is created: it sends it from an effect,
and effects run when Angular next synchronises, which in an application happens by itself a moment
later. A test is not an application; nothing runs until the test says so, and `TestBed.tick()` is
how it says so. The same is true of anything else built on effects or on change detection, which
is why most of this lesson's tests have a `tick()` or a `whenStable()` in them.

```
ana@dev:~/planner$ sed -i 's|^    // TestBed.tick();|    TestBed.tick();|' src/app/planner-store.spec.ts
```

## What the fake server is good for

The second test is the valuable one. A failed `PATCH` is hard to produce by hand: lesson 12 had to
stop the API within a five-second window to see one. Here it is one line, and it runs every time. Answering
with an error is the same call as answering with data, `flush`, with a `status`; a network failure
with no answer at all is `error(new ProgressEvent('error'))`. Each of the store's paths can have a
test, the retries of a `500` included, without anything being down.

What a fake server does not test is the real one. If the API changed its error to a different
field, these tests would go on passing against the answer they were written with. That is the
level above this one, and the last section of this lesson says who checks it.
