---
title: Prettier, which settles the arguments
version: 1
---

**A formatter rewrites code into one layout, so that nobody chooses one.** Linting is about mistakes;
formatting is about where the line breaks go, which is no mistake at all but generates more review
comments than anything else. **Prettier** takes the decision away: it reads the code, throws its layout
away, and prints it again by its own rules.

```
ana@dev:~/planner$ npm install --save-dev prettier@3.9.10

added 1 package, and audited 294 packages in 768ms

66 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npx prettier --check . 2>&1 | tail -n 3
[warn] src/WeekSummary.tsx
[warn] vite.config.ts
[warn] Code style issues found in 38 files. Run Prettier with --write to fix.
```

**38 files**, nearly every file in the project. Prettier's defaults are semicolons, double quotes and
lines of 80 characters, and the planner was written without semicolons, with single quotes and lines up
to 100. Prettier has very few options, on purpose, and those three are among them, in
`.prettierrc.json`:

```json
{
  "semi": false,
  "singleQuote": true,
  "printWidth": 100
}
```

```
ana@dev:~/planner$ npx prettier --check .
Checking formatting...
[warn] server/api.mjs
[warn] src/main.tsx
[warn] src/week.ts
[warn] tsconfig.json
[warn] Code style issues found in 4 files. Run Prettier with --write to fix.
ana@dev:~/planner$ git add -A && git commit -q -m "Add ESLint and Prettier" && npx prettier --write . > /dev/null && git diff --stat
 server/api.mjs |  7 +++++--
 src/main.tsx   |  4 +++-
 src/week.ts    | 10 ++++++++--
 tsconfig.json  |  5 +----
 4 files changed, 17 insertions(+), 9 deletions(-)
ana@dev:~/planner$ sed -n '26,42p' src/week.ts
export function formatDay(day: string): string {
  return noon(day).toLocaleDateString('en-GB', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    timeZone: 'UTC',
  })
}

export function formatWeek(monday: string): string {
  return noon(monday).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  })
}
```

**Four files left**, and they are the interesting ones: the places where the code's layout differed
from Prettier's in something that is not a setting. The tools added so far are committed first, so that
the diff shows only what Prettier did. In `src/week.ts`, the two option objects of lesson 3 had been
written on one line each, inside a call that was already broken across lines, and Prettier put each
property on a line of its own, as the `sed` shows. The others are similar. `tsconfig.json` goes the other way: two short objects that fit on
one line are put on one.

You do not have to agree with each change, and that is the point. **The layout is now a fact about the
tool, not about whoever last touched the file**, and a review can be about what the code does. Editors
can run Prettier on every save, so in practice the code is formatted before anyone sees it.
