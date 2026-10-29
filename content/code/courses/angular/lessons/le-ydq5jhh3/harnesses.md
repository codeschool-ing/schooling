---
title: Harnesses, for components somebody else wrote
version: 1
---

**A component harness is a test API for a component, written by the component's authors, so a
test can work it without knowing its HTML.** The next test ticks "Hide sessions that are done". The
box is a `mat-checkbox`, and the obvious way to tick it would be to find the `<input>` inside it and
click that. That works today, and ties the test to how Material builds a checkbox inside, which is
Material's business and changes between versions. A harness is the stable part: Material ships one
for each of its components as the supported way to test them, and its methods are meant to stay
the same when the markup underneath changes.

```schooling-example
{"language": "typescript", "file": "src/app/course-sessions/course-sessions.spec.ts", "parts": [
 {"code": "// src/app/course-sessions/course-sessions.spec.ts\nimport { TestbedHarnessEnvironment } from '@angular/cdk/testing/testbed';\nimport { provideHttpClient } from '@angular/common/http';\nimport { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';\nimport { TestBed } from '@angular/core/testing';\nimport { MatCheckboxHarness } from '@angular/material/checkbox/testing';", "note": "Two imports more than before: the harness environment for `TestBed`, from the CDK, and the checkbox's harness, from Material's own `testing` entry point."},
 {"code": "import { PlannerData } from '../planner';\nimport { CourseSessions } from './course-sessions';\n\nconst planner: PlannerData = {\n  courses: [{ id: 'git', name: 'Git' }],\n  sessions: [\n    { id: 3, courseId: 'git', date: '2026-10-27', minutes: 40, done: false },\n    { id: 1, courseId: 'git', date: '2026-10-19', minutes: 30, done: true },\n    { id: 2, courseId: 'html-css', date: '2026-10-20', minutes: 60, done: false },\n  ],\n};\n\ndescribe('CourseSessions', () => {\n  beforeEach(() => {\n    localStorage.clear();\n    TestBed.configureTestingModule({\n      imports: [CourseSessions],\n      providers: [provideHttpClient(), provideHttpClientTesting()],\n    });\n  });\n\n  async function render() {\n    const fixture = TestBed.createComponent(CourseSessions);\n    fixture.componentRef.setInput('courseId', 'git');\n    TestBed.tick();\n    TestBed.inject(HttpTestingController).expectOne('/api/planner').flush(planner);\n    await fixture.whenStable();\n    return fixture;\n  }\n\n  it(\"lists the course's sessions, oldest first\", async () => {\n    const fixture = await render();\n    const rows = [...(fixture.nativeElement as HTMLElement).querySelectorAll('li')];\n    expect(rows.map((li) => li.textContent?.trim())).toEqual(['Mon 19 Oct, 30 minutes', 'Tue 27 Oct, 40 minutes']);\n  });\n"},
 {"code": "  it('hides the sessions that are done', async () => {\n    const fixture = await render();\n    const loader = TestbedHarnessEnvironment.loader(fixture);\n    const hide = await loader.getHarness(MatCheckboxHarness.with({ label: 'Hide sessions that are done' }));\n    await hide.check();\n", "note": "The loader finds harnesses inside the fixture. `with({ label })` picks the checkbox a person would pick, by what it says, and `check()` ticks it the way a click would, events and all, and waits until Angular has drawn the result."},
 {"code": "    const rows = await loader.getAllHarnesses(MatCheckboxHarness.with({ ancestor: 'app-session-list' }));\n    expect(await Promise.all(rows.map((row) => row.getLabelText()))).toEqual(['Tue 27 Oct, 40 minutes']);\n  });\n});", "note": "The session rows are `mat-checkbox`es too, so the same harness reads them, narrowed to those inside the list."}
]}

```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*course-sessions|Tests '
 ✓ |planner| src/app/course-sessions/course-sessions.spec.ts (2 tests) 366ms
      Tests  21 passed (21)
```

Every harness method returns a promise, which is why the test is `async` and each call has an
`await`: a harness waits for Angular to finish after each action, so the test never has to call
`whenStable()` itself. The methods are the questions a person would ask of the control,
`isChecked()`, `getLabelText()`, `isDisabled()`, and the actions they would take, `check()`,
`toggle()`. A harness for a dialog opens it and reads its title; one for a select opens it and picks
an option by its text.

**Harnesses are not only Material's.** The CDK's `ComponentHarness` is the class Material's extend,
and a component of your own can have one: a class that knows the component's selector and how to
find its parts, with methods named for what a person does. For the planner's own components it is
not worth it, because their markup is the planner's own and the tests can read it. It becomes worth
it for a component used in many places, by people who should not need to know its insides, which
is exactly the position Material is in.
