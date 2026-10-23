---
title: The same tests in Jest
version: 1
---

**Jest is the runner most JavaScript projects used before Vitest.** The tests read almost the same
in it, and what differs is everything around them. You will meet it in existing projects, so this
section runs `planner.test.ts` under Jest 30.5.2 in a folder of its own, `~/planner-jest`, beside the
planner rather than inside it, so the two runners never pick up each other's files.

```
ana@dev:~$ mkdir planner-jest
ana@dev:~$ cd planner-jest
ana@dev:~/planner-jest$ npm init -y > /dev/null
ana@dev:~/planner-jest$ npm pkg set type=module
ana@dev:~/planner-jest$ npm install --save-exact -D jest@30.5.2 @jest/globals@30.5.2 ts-jest@29.4.15 typescript@6.0.3
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 291 packages, and audited 292 packages in 12s

found 0 vulnerabilities
ana@dev:~/planner-jest$ cp ../planner/src/planner.ts ../planner/public/courses.json .
```

Jest runs JavaScript. To read TypeScript it needs a transformer, and `ts-jest` is the one that runs
the TypeScript compiler; it brings its own copy of `typescript`, pinned like the planner's. The test
is the planner's, with one line changed, because Jest's functions come from `@jest/globals` rather
than from `vitest`, and the data now sits beside it:

```typescript
// planner.test.ts
import { describe, expect, test } from "@jest/globals";
import { weekOf, weekTotal, type Plan } from "./planner";
import data from "./courses.json";

const plan: Plan = data;

describe("weekOf", () => {
  test("a Wednesday's week runs from the Monday before to the Sunday after", () => {
    expect(weekOf("2026-10-21")).toEqual(["2026-10-19", "2026-10-25"]);
  });
});

describe("weekTotal", () => {
  test("adds every session of the week, done or not", () => {
    expect(weekTotal(plan, "2026-10-21")).toBe(160);
  });
});
```

And one file to tell Jest which transformer to use. Save it as `jest.config.js`:

```javascript
// jest.config.js
export default {
  preset: "ts-jest",
  testEnvironment: "node",
};
```

```
ana@dev:~/planner-jest$ npx jest
ts-jest[config] (WARN) message TS151001: If you have issues related to imports, you should consider setting `esModuleInterop` to `true` in your TypeScript configuration file (usually `tsconfig.json`). See https://blogs.msdn.microsoft.com/typescript/2018/01/31/announcing-typescript-2-7/#easier-ecmascript-module-interoperability for more information.
FAIL ./planner.test.ts
  ● Test suite failed to run

    planner.test.ts:4:18 - error TS7042: Module './courses.json' was resolved to '/home/ana/planner-jest/courses.json', but '--resolveJsonModule' is not used.

    4 import data from "./courses.json";
                       ~~~~~~~~~~~~~~~~

Test Suites: 1 failed, 1 total
Tests:       0 total
Snapshots:   0 total
Time:        1.285 s
Ran all test suites.
```

**The tests did not fail; the file did not compile.** ts-jest type-checks before it runs, and
TypeScript refuses to import a `.json` file unless `resolveJsonModule` is on. In the planner it is on
without being written down, because Vite's template sets `moduleResolution` to `bundler` and that
setting allows it; a folder with no `tsconfig.json` gets TypeScript's older defaults, which do not.
That is the difference between the two runners in one line: Vitest uses the project's Vite and
TypeScript setup, and Jest is a second setup you keep beside it.
The warning above it asks for `esModuleInterop` as well. Save this as `tsconfig.json`:

```json
{
  "compilerOptions": {
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  }
}
```

```
ana@dev:~/planner-jest$ npx jest
Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.313 s
Ran all test suites.
```

`isolatedModules` tells ts-jest to compile each file on its own, which is how Vite treats them too.

## What is the same and what is not

| | Vitest | Jest |
|---|---|---|
| tests | `describe`, `test`, `expect` from `vitest` | the same names, from `@jest/globals` |
| a function that records calls | `vi.fn()` | `jest.fn()` |
| a stopped clock | `vi.useFakeTimers()`, `vi.setSystemTime()` | `jest.useFakeTimers()`, `jest.setSystemTime()` |
| a document | `@vitest-environment jsdom` | `@jest-environment jsdom`, with `jest-environment-jsdom` installed |
| TypeScript | read through Vite, nothing to set up | a transformer (`ts-jest`, `babel-jest`, `@swc/jest`) and its configuration |

**The assertions are the same library in all but name**, which is why moving a suite from one to the
other is mostly a search and replace. Choose by the project: a Vite project is already configured for
Vitest, and an existing Jest suite keeps working where it is.
