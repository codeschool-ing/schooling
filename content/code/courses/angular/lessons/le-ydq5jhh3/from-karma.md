---
title: Karma and Jasmine, and the move to Vitest
version: 1
---

**Until Angular 21, `ng new` set up Karma and Jasmine; from Angular 21 it sets up Vitest, and most
Angular code you will open at work still has the first two.** Karma is a runner that opens a real
browser, Chrome usually, and runs the tests inside it; Jasmine is the library that gives `describe`,
`it`, `expect` and spies. The Karma project was deprecated in 2023, and that is much of the reason for the
change: a runner nobody maintains is a runner nobody fixes.

Most of a test reads the same in both. `describe`, `it`, `beforeEach`, `expect(...).toBe(...)` and
everything `TestBed` does are identical, which is why this course's tests would mostly run under
Karma. The differences are in the spies and a few matchers. A spec written the Jasmine way, as a
project from before Angular 21 would have it:

```typescript
// src/app/minutes-pipe.jasmine.spec.ts
import { MinutesPipe } from './minutes-pipe';

describe('MinutesPipe, as Karma projects wrote it', () => {
  it('writes an hour and a half in words', () => {
    const pipe = new MinutesPipe();
    const transform = spyOn(pipe, 'transform').and.callThrough();
    expect(pipe.transform(90)).toBe('1 hour 30 minutes');
    expect(transform).toHaveBeenCalledOnceWith(90);
  });
});
```

`spyOn` wraps a method so a test can ask how it was called; `.and.callThrough()` lets the real
method run as well. Under Vitest neither name exists, and the build stops before a test runs:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -A4 ERROR
✘ [ERROR] TS2304: Cannot find name 'spyOn'. [plugin angular-compiler]

    src/app/minutes-pipe.jasmine.spec.ts:7:22:
      7 │     const transform = spyOn(pipe, 'transform').and.callThrough();
        ╵                       ~~~~~
--
✘ [ERROR] TS2551: Property 'toHaveBeenCalledOnceWith' does not exist on type 'Assertion<any>'. Did you mean 'toHaveBeenCalledOnce'? [plugin angular-compiler]

    src/app/minutes-pipe.jasmine.spec.ts:9:22:
      9 │     expect(transform).toHaveBeenCalledOnceWith(90);
        ╵                       ~~~~~~~~~~~~~~~~~~~~~~~~
```

The CLI has a schematic for this move. It is marked experimental, so it is run on one file and its
work is read before it is trusted:

```
ana@dev:~/planner$ npx ng generate @schematics/angular:refactor-jasmine-vitest --include src/app/minutes-pipe.jasmine.spec.ts
    Jasmine to Vitest Refactoring Summary:
    - 1 test file(s) scanned.
    - 1 file(s) transformed.
CREATE jasmine-vitest-20261029T235741782Z.md (350 bytes)
UPDATE src/app/minutes-pipe.jasmine.spec.ts (473 bytes)
```

```
ana@dev:~/planner$ cat src/app/minutes-pipe.jasmine.spec.ts
// src/app/minutes-pipe.jasmine.spec.ts
import { MinutesPipe } from './minutes-pipe';

describe('MinutesPipe, as Karma projects wrote it', () => {
  it('writes an hour and a half in words', () => {
    const pipe = new MinutesPipe();
    const transform = vi.spyOn(pipe, 'transform');
    expect(pipe.transform(90)).toBe('1 hour 30 minutes');
    expect(transform).toHaveBeenCalledTimes(1);
    expect(transform).toHaveBeenCalledWith(90);
  });
});
```

`spyOn` became `vi.spyOn`, which calls the real method by default, so `.and.callThrough()` had
nothing left to say. `toHaveBeenCalledOnceWith`, which Vitest does not have, became the two checks it
always meant. The report it wrote says nothing needed a person; when something does, it lists it as
a `TODO`, with the file and the line.

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓.*jasmine|Tests '
 ✓ |planner| src/app/minutes-pipe.jasmine.spec.ts (1 test) 2ms
      Tests  22 passed (22)
```

The file was only for this section, and the report is not part of the project:

```
ana@dev:~/planner$ rm src/app/minutes-pipe.jasmine.spec.ts jasmine-vitest-*.md
```

The other half of a real move is `angular.json`. A project on Karma names the `@angular/build:karma`
builder, or the older `@angular-devkit/build-angular:karma`, under `test`, with a `karma.conf.js`
beside it. The planner's says `@angular/build:unit-test`, the builder that runs Vitest, and that
builder can also run Karma, with `"runner": "karma"`: a project can change builder first and runner
second, with its tests green between the two steps.

| Jasmine, under Karma | Vitest |
| --- | --- |
| `spyOn(object, 'method')` | `vi.spyOn(object, 'method')` |
| `jasmine.createSpy()` | `vi.fn()` |
| `.and.returnValue(x)` | `.mockReturnValue(x)` |
| `toHaveBeenCalledOnceWith(x)` | `toHaveBeenCalledTimes(1)` and `toHaveBeenCalledWith(x)` |
| a real browser, opened by Karma | jsdom in Node.js, or a real browser if asked for |
