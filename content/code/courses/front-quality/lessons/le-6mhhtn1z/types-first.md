---
title: The layer that runs nothing
version: 1
---

**The cheapest test is the one you do not write.** The type checker reads every file on every save
and finds a whole class of mistakes before anything runs. In this project that is `tsc`, the
TypeScript compiler, told by the template's `tsconfig.json` to check and not to emit any files.

Here is the kind of mistake it exists for. `FormData.get` returns what the browser read from a
field, which is a string, a file or nothing. Leave out the `Number(…)` around the minutes in
`src/view.ts`, and the form hands `addSession` the wrong kind of value:

```
ana@dev:~/planner$ npx tsc --noEmit
src/view.ts(45,66): error TS2345: Argument of type 'FormDataEntryValue | null' is not assignable to parameter of type 'number'.
  Type 'null' is not assignable to type 'number'.
ana@dev:~/planner$ git checkout src/view.ts
Updated 1 path from the index
ana@dev:~/planner$ npx tsc --noEmit
```

The message names the file, the line and the column, `src/view.ts(45,66)`, and says exactly what
was wrong: a value that can be a string, a file or `null`, passed where a number was declared.
`git checkout` put the file back, and the second run printed nothing, which is `tsc` saying yes.

**Without the type checker this mistake runs.** JavaScript would pass the string `"15"` to
`addSession`, `Number.isInteger("15")` would be false, and the person filling in the form would be
told that 15 is not a whole number from 1 to 600. A unit test of `addSession` would pass, because it
calls the function with numbers. A component test that typed into the form would catch it, a second
later and one layer up. The checker caught it at the cost of reading.

## What it cannot do

`tsc` knows the shapes of values, not whether they are right. `weekTotal(plan, "2026-10-21")`
type-checks whatever it returns, so long as it returns a number, and a wrong number is still a
number. It also takes the data on trust: `await response.json()` is typed as anything at all, and
`main.ts` assigns it to a `Plan` without looking. If `courses.json` said `"minutes": "45"`, the
checker could not know. A runtime check of data from outside, which a server would do on what it
receives, is outside what any amount of static checking can give you.

So the static layer is the base and not the building: it removes the mistakes that are about shape,
and leaves the ones about meaning to the tests.

## It runs in the build

The template's `build` script is `tsc && vite build`, so `npm run build` refuses to build a project
that does not type-check. `npm run dev` does not check: Vite strips the types and serves the file, to
stay fast, which is why the editor's red underline and the `tsc` run are the places a type error
shows up while you work.
