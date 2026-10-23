---
title: The types check the props, but not while you browse
version: 1
---

**The compiler knows every component's contract, and Vite does not ask it.** That is a deliberate
trade, and knowing it is the difference between trusting a page that renders and trusting a page
that is correct. This section makes one mistake on purpose and follows it through the three places
it could be caught.

The mistake: `App` passes `WeekSummary` a number where its props ask for a string.

```
ana@dev:~/planner$ sed -i 's/<WeekSummary monday={MONDAY} sessions={thisWeek} \/>/<WeekSummary monday={19} sessions={thisWeek} \/>/' src/App.tsx
ana@dev:~/planner$ grep -n "<WeekSummary" src/App.tsx
14:      <WeekSummary monday={19} sessions={thisWeek} />
ana@dev:~/planner$ look http://localhost:5173/ 2>&1 | head -n 5
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of Invalid Date
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ npx tsc -b
src/App.tsx(14,20): error TS2322: Type 'number' is not assignable to type 'string'.
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

src/App.tsx(14,20): error TS2322: Type 'number' is not assignable to type 'string'.
ana@dev:~/planner$ sed -i 's/monday={19}/monday={MONDAY}/' src/App.tsx
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
```

In order:

1. **The page drew.** `look` shows the screen, with "Week of Invalid Date" where the date should be.
   Vite removes types without checking them, which is what makes it fast enough to update the page
   while you are still typing, and it means a type error never stops the development server.
2. **`npx tsc -b` refused it**, with the file, the line and the column, `src/App.tsx(14,20)`, and a
   sentence that says exactly what is wrong. `tsc` is the TypeScript compiler; `-b` builds the
   project the way the three `tsconfig` files describe, and here it only checks, because the
   template tells it not to write any output.
3. **`npm run build` refused it too**, because the template's build script is `tsc -b && vite
   build`, and `&&` runs the second command only when the first succeeds. Nothing that fails the
   type check can be published.

Your editor is the fourth place, and the best one: an editor that understands TypeScript underlines
`monday={19}` as you type it, with the same sentence. Visual Studio Code does it with no extension.

**Run `npx tsc -b` before you trust a change**, or keep it running in a terminal of its own with
`npx tsc -b --watch`. A page that renders has only shown that nothing threw; this one rendered a
wrong date with every number below it right, because `App` computed the week from its own constant
and the mistake reached only the line that read the prop. Lesson 23 adds the type check to the
commands that run before every commit, and lesson 19 is about writing types that catch more.
