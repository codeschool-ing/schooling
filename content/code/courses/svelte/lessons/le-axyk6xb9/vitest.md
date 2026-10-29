---
title: Vitest, and the first test
version: 1
---

**A test is a small program that runs a piece of the planner and says whether it did what it should.**
Written once, it runs in a second, every time anything changes, and it remembers what the planner was
supposed to do long after the person who wrote it has forgotten. This lesson writes two kinds: **unit
tests**, which call a function or render a component directly, with **Vitest**; and **end-to-end
tests**, which drive the whole planner in a real browser, with **Playwright**.

Vitest is built on Vite, so it reads the project's own `vite.config.js`, with the SvelteKit plugin and
the `#lib` imports, and compiles `.svelte` and `.ts` files the way the dev server does. Install it:

```
ana@dev:~/planner$ npm install --save-dev vitest@5.0.5

added 15 packages, removed 1 package, and audited 74 packages in 3s

17 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Tell it where the tests are. Replace `vite.config.js`:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-node';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},\n\n\t\t\t// adapter-node builds a Node server: `npm run build`, then `node build`.\n\t\t\tadapter: adapter(),\n\t\t\t// The address the planner is served at, given when it is built:\n\t\t\t//   ORIGIN=http://localhost:3000 npm run build\n\t\t\tpaths: { origin: process.env.ORIGIN }\n\t\t})\n\t],\n"},
 {"code": "\ttest: {\n\t\tinclude: ['src/**/*.test.ts']\n\t}\n});", "note": "`test` is read by Vitest and ignored by Vite. A test file sits beside the file it tests, and its name ends in `.test.ts`."}
]}
```

and give it a script:

```
ana@dev:~/planner$ npm pkg set scripts.test:unit='vitest run'
```

`vitest run` runs every test once and stops. `vitest` on its own would keep watching, and run the tests
again whenever a file is saved.

## The first test file

The rules about weeks are the oldest code in the planner, and every total depends on them. Save this as
`src/lib/week.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/week.test.ts", "parts": [
 {"code": "// week.test.ts: the date rules, one fact at a time.\nimport { describe, expect, test } from 'vitest';\nimport { addDays, format, inWeek, isDate, mondayOf } from '#lib/week.js';\n"},
 {"code": "describe('mondayOf', () => {\n\ttest('a Wednesday belongs to the Monday before it', () => {\n\t\texpect(mondayOf('2026-10-21')).toBe('2026-10-19');\n\t});\n\n\ttest('a Monday is its own Monday', () => {\n\t\texpect(mondayOf('2026-10-19')).toBe('2026-10-19');\n\t});\n\n\ttest('a Sunday ends the week, rather than starting the next', () => {\n\t\texpect(mondayOf('2026-10-25')).toBe('2026-10-19');\n\t});\n});\n", "note": "`describe` groups tests under a name, and `test` is one test: a name that says what should be true, and a function that checks it. `expect(x).toBe(y)` fails the test when `x` is not `y`."},
 {"code": "test('addDays crosses the end of a month', () => {\n\texpect(addDays('2026-10-30', 3)).toBe('2026-11-02');\n});\n\ntest('inWeek includes the Sunday and not the next Monday', () => {\n\texpect(inWeek('2026-10-25', '2026-10-19')).toBe(true);\n\texpect(inWeek('2026-10-26', '2026-10-19')).toBe(false);\n});\n"},
 {"code": "test.each([\n\t['2026-10-19', true],\n\t['2026-02-31', false],\n\t['19/10/2026', false],\n\t['', false],\n\t[20261019, false]\n])('isDate(%j) is %s', (value, expected) => {\n\texpect(isDate(value)).toBe(expected);\n});\n\ntest('format writes the day, a short month and the year', () => {\n\texpect(format('2026-10-19')).toBe('19 Oct 2026');\n});", "note": "`test.each` runs one test per row of the table, with `%j` and `%s` in the name replaced by the row's values. Edge cases are cheap to list this way, and each fails on its own line."}
]}
```

```
ana@dev:~/planner$ npm run test:unit

> planner@0.0.1 test:unit
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/lib/week.test.ts (11 tests) 22ms

 Test Files  1 passed (1)
      Tests  11 passed (11)
   Start at  22:34:16
   Duration  197ms (transform 45%, tests 28%, import 19%, worker 8%)
```

**Eleven tests, one file, a fraction of a second.** The one about Sunday is the kind worth writing:
`mondayOf` works by counting back from the day of the week, JavaScript numbers Sunday as 0, and getting
that wrong would put every Sunday session in the following week, in a way nobody would notice until a
total was off on a Sunday.
