---
title: Biome, one tool for both
version: 1
---

**Biome does a linter's job and a formatter's job in one program**, written in Rust like Oxlint. It also
sorts imports. Installed, initialised with its defaults, run over `src`, then given Prettier's settings
and run again, with the last command listing what was left:

```
ana@dev:~/planner$ npm install --save-dev @biomejs/biome@2.6.2

added 2 packages, and audited 296 packages in 2s

67 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npx biome init > /dev/null && npx biome check src 2>&1 | grep -E '^(Checked|Found)'
Checked 35 files in 20ms. No fixes applied.
Found 41 errors.
Found 1 warning.
ana@dev:~/planner$ npx biome migrate prettier --write > /dev/null && npx biome check src 2>&1 | grep -E '^(Checked|Found)'
Checked 35 files in 18ms. No fixes applied.
Found 6 errors.
Found 1 warning.
ana@dev:~/planner$ npx biome check src 2>&1 | grep '^src' | sed 's/ ━.*//'
src/main.tsx:41:12 lint/style/noNonNullAssertion
src/AddSessionForm.test.tsx:5:1 assist/source/organizeImports  FIXABLE 
src/AddSessionForm.tsx:5:1 assist/source/organizeImports  FIXABLE 
src/Dialog.tsx:1:1 assist/source/organizeImports  FIXABLE 
src/Field.tsx:1:1 assist/source/organizeImports  FIXABLE 
src/WeekScreen.tsx:1:1 assist/source/organizeImports  FIXABLE 
src/usePlanner.ts:1:1 assist/source/organizeImports  FIXABLE 
```

`biome init` wrote a `biome.json` with Biome's defaults, and against them the planner had **41 errors**,
almost all of them layout: Biome formats with tabs and double quotes unless told otherwise. **`biome
migrate prettier`** read `.prettierrc.json` and wrote the same choices into `biome.json`, and then only six
errors and one warning were left:

- **`organizeImports`, six times**: Biome sorts the names inside each import, and puts types where its
  order says. It can fix these itself, which is what `FIXABLE` means.
- **`noNonNullAssertion`**, in `main.tsx`: `document.getElementById('root')!`. Lesson 12 said a `!` is a
  claim you must be able to defend, and this one can be, since `index.html` has the element. Biome cannot
  know that, so it asks.

**One tool or several** is a real choice, and both are common. Biome is one dependency, one
configuration and one very fast command; Oxlint with Prettier, or ESLint with Prettier, is several, with
more plugins between them. The planner keeps Prettier and the linters it already has, so Biome goes:

```
ana@dev:~/planner$ npm uninstall @biomejs/biome && rm biome.json && git status --short

removed 2 packages, and audited 294 packages in 612ms

66 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
 M server/api.mjs
 M src/main.tsx
 M src/week.ts
 M tsconfig.json
```

What is left to commit is what Prettier changed, in four files.
