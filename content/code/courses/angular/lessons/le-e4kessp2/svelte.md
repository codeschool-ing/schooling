---
title: Svelte
version: 1
---

**Svelte is a compiler: a component is written in its own small language, and the build turns it
into plain JavaScript that updates the page directly.** There is less of Svelte in the page than of
any of the others, because much of what the others do while running, Svelte did while building.
Its project comes from the same generator:

```
ana@dev:~/compare$ npm create vite@9.3.1 -- svelte --template svelte-ts --no-immediate

> npx
> cva svelte --template svelte-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/compare/svelte...
│
└  Done. Now run:

  cd svelte
  npm install
  npm run dev
```

```
ana@dev:~/compare/svelte$ npm install

added 49 packages, and audited 50 packages in 4s

2 low severity vulnerabilities

Some issues need review, and may require choosing
a different dependency.

Run `npm audit` for details.
```

```
ana@dev:~/compare/svelte$ npm install --save-exact svelte@5.57.3 @sveltejs/vite-plugin-svelte@7.3.1 @tsconfig/svelte@5.0.8 @types/node@22.20.5 svelte-check@4.7.7 typescript@6.0.3 vite@8.3.5

added 2 packages, changed 2 packages, and audited 52 packages in 2s

2 low severity vulnerabilities

Some issues need review, and may require choosing
a different dependency.

Run `npm audit` for details.
```

Two low ones, both installs. The audit says what they are:

```
ana@dev:~/compare/svelte$ npm audit 2>&1 | head -9
# npm audit report

deepmerge  >=4.2.0
deepmerge mergeObject() allows prototype poisoning of returned objects - https://github.com/advisories/GHSA-gcqx-w48m-w2h4
No fix available
node_modules/deepmerge
  @sveltejs/vite-plugin-svelte  *
  Depends on vulnerable versions of deepmerge
  node_modules/@sveltejs/vite-plugin-svelte
```

`deepmerge`, a small library the Svelte plugin for Vite uses while building, has an advisory and no
fixed version. It runs on your machine during a build and is not in the page. For a card deleted at
the end of this lesson that is the end of it; in a real project it is an entry to note, and to read
again when the plugin is updated.

```
ana@dev:~/compare/svelte$ rm -r src/App.svelte src/lib src/app.css
```

The card:

```schooling-example
{"language": "html", "file": "src/WeekCard.svelte", "parts": [
 {"code": "<!-- src/WeekCard.svelte: one course's week, the Svelte way -->\n<script lang=\"ts\">\n  console.log('Svelte: the script runs');", "note": "A component is a `.svelte` file: a script, then the markup."},
 {"code": "  let sessions = $state([\n    { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },\n    { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },\n  ]);\n  const planned = $derived(sessions.reduce((sum, s) => sum + s.minutes, 0));\n  const done = $derived(sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));\n</script>\n", "note": "`$state` and `$derived` are runes: words the Svelte compiler reads and turns into its own update code. The state is a plain array to the code that uses it, written to directly."},
 {"code": "<section>\n  <h2>JavaScript</h2>\n  <ul>\n    {#each sessions as s (s.id)}\n      <li>\n        <label><input type=\"checkbox\" bind:checked={s.done} /> {s.date}, {s.minutes} minutes</label>\n      </li>\n    {/each}\n  </ul>\n  <p>{done} of {planned} minutes done</p>\n</section>", "note": "`{#each}` is the loop, with the key in parentheses, and `bind:checked` writes the box back into `s.done`."}
]}
```

```typescript
// src/main.ts: the card, and nothing else, in the page's #app
import { mount } from 'svelte';
import WeekCard from './WeekCard.svelte';

mount(WeekCard, { target: document.getElementById('app')! });
```

```
ana@dev:~/compare/svelte$ look http://localhost:5173/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
Svelte: the script runs
[vite] connected.
-- check Sat 24 Oct, 50 minutes
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

**Once** again. The script ran when the card was created, and the tick reached the two `$derived`s and
the paragraph through code the compiler wrote for exactly those, with no framework deciding at run
time what to look at. Stop the dev server.
